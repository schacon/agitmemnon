require 'tempfile'

module Agitmemnon
  class Repo

    OBJ_NONE = 0
    OBJ_COMMIT = 1
    OBJ_TREE = 2
    OBJ_BLOB = 3
    OBJ_TAG = 4
    OBJ_OFS_DELTA = 6
    OBJ_REF_DELTA = 7

    MAX_OBJ_SIZE = 100_000
    MAX_ROW_SIZE = 1_000_000
    MIN_ROW_SIZE = 100_000
    
    SHA1Size = 20

    class PackFragment < StringIO
      attr_reader :objtype, :base_sha, :object_size
      def process
        c = self.read(1).getord(0)
        @object_size = c & 0xf
        @objtype = (c >> 4) & 7
        shift = 4
        offset = 1
        while c & 0x80 != 0
          c = self.read(1).getord(0)
          @object_size |= ((c & 0x7f) << shift)
          shift += 7
          offset += 1
        end

        if @objtype == OBJ_REF_DELTA
          @base_sha = self.read(SHA1Size).unpack("H*").first
        end
      end
      
      def get_raw
        self.seek(0)
        self.read
      end
      
      def include?
        @objtype != OBJ_OFS_DELTA
      end
    end
    
    attr_accessor :repo_handle, :grit, :client

    def initialize(repo_handle, path)
      raise if repo_handle == '__main_listing__'  # reserved word      
      @client = Cassandra.new(Agitmemnon.table)
      @repo_handle = repo_handle
      @grit = Grit::Repo.new(path)
    end

    def update(load_packfile = true)
      update_objects(load_packfile)
      update_refs
      update_repo_info
    end

    protected

    def update_objects(load_packfile)
      # get current refs
      current_refs = @grit.refs.map { |h| h.commit.id }.select { |r| r.size == 40 }
      crefs = @client.get(:Repositories, @repo_handle)
      cass_refs = crefs.map { |t, hash| hash.map { |a, sha| sha } } rescue []
      cass_refs = cass_refs.flatten.uniq.select { |r| r.size == 40 }
      
      # find all commits between that ref and the heads
      have_refs = (cass_refs - current_refs).map { |r| "^#{r}"}.join(' ')
      need_refs = (current_refs - cass_refs).join(' ')
      objects = @grit.objects("#{need_refs} #{have_refs}")

      puts 'HAVE:' + have_refs
      puts 'NEED:' + need_refs
      
      load_objects(objects)
      if load_packfile
        load_packfile_caches
      end
    end

    def load_packfile_caches
      # go through the existing packfiles looking for groups of objects within objlist
      # add 1M at a time into cassandra
      # remove from objlist

      puts "Generating Packfile"

      packname = @repo_handle + Digest::SHA1.hexdigest(Time.now().to_s)
      packfile_pack = '/tmp/' + packname + '.pack'
      packfile_idx = '/tmp/' + packname + '.idx'
      Dir.chdir(@grit.path) do
        `git rev-list --objects master | git pack-objects --stdout > #{packfile_pack}`
        `git index-pack -o #{packfile_idx} #{packfile_pack}`
      end
      
      pack = Grit::GitRuby::Internal::PackStorage.new(packfile_pack)
      
      shas = {}
      pack_data = []
      total_size = File.size(packfile_pack) - 20
      
      pack.each_entry do |sha, offset|
        sha = sha.unpack("H*").first
        pack_data << [offset, sha]
      end

      last = nil
      final = []
      pack_data = pack_data.sort
      
      pack_data.each do |offset, sha|
        if last
          size = offset - last[0]
          final << [last[1], last[0], size]
        end
        last = [offset, sha]
      end
      size = total_size - last[0]
      final << [last[1], last[0], size]
      
      cp = {'data' => '', 'size' => 0, 'count' => 0}
      cp_entries = ''

      # read each of the objects and put them into a binary blob 
      # to be sent to cassandra
      packfile = File.open(pack.name, 'rb')
      final.each do |sha, offset, size|
        if size < MAX_OBJ_SIZE
          if (cp['size'] + size) > MAX_ROW_SIZE
            # save data, reset buffers
            save_data(cp, cp_entries)
            cp = {'data' => '', 'size' => 0, 'count' => 0}
            cp_entries = ''
          end
          packfile.seek(offset)
          data = PackFragment.new(packfile.read(size, 'rb'))
          data.process
          #puts [sha, data.size, data.object_size, data.objtype, data.base_sha].join("\t")
          cp_entries += "#{sha}:#{cp['size']}:#{data.size}:#{data.base_sha}\n"
          cp['size'] += data.size
          cp['data'] += data.get_raw
          cp['count'] += 1
        end
      end
      save_data(cp, cp_entries)
    end

    # PackCacheIndex (projectname) [(cache_key) => (list of objects/offset/size), ...]
    # PackCache (cache_key) [:size => (size), :count => (count), :data => (list of objects)]
    def save_data(cp, cp_entries)
      # save cp_entries
      if cp['size'] > MIN_ROW_SIZE
        cache_key = @repo_handle + Digest::SHA1.hexdigest(cp_entries)
        puts "INSERTING:" + cp['data'].size.to_s
        cp['data'] = Base64.encode64(cp['data'])
        cp['size'] = cp['size'].to_s
        cp['count'] = cp['count'].to_s
        @client.insert(:PackCache, cache_key, cp)
        @client.insert(:PackCacheIndex, @repo_handle, {cache_key => cp_entries})
      end
    end

    def load_objects(objects)
      # foreach object
      objects.each do |sha|
        puts sha
        obj = @grit.git.ruby_git.get_raw_object_by_sha1(sha)
        #puts "#{obj.type}:#{obj.content.size}:#{sha}"
        object = {'type' => obj.type.to_s, 
                  'size' => obj.content.length.to_s, 
                  'data' => Base64.encode64(Zlib::Deflate.deflate(obj.content)) }
        if obj.type.to_s == 'commit'
          # save the jsonified version
          commit_hash = Grit::GitRuby::GitObject.from_raw(obj).to_hash
          object['json'] = commit_hash.to_json
          @client.insert(:Objects, sha, object)      
          
          # save the commit diff
          #diff = grit.diff(sha, "#{sha}^")
          #@client.insert(:CommitDiffs, sha, {'diff' => diff}) # TODO : colored diff?

          # save the object and parentage list
          obs = @grit.diff_objects(sha, commit_hash['parents'].size > 0)
          revtree = { 'parents' => commit_hash['parents'].join(":"), 
                      'objects' => obs.join(":") }
          @client.insert(:RevTree, @repo_handle, {sha => revtree})
        elsif obj.type.to_s == 'tree'
          json = Grit::GitRuby::GitObject.from_raw(obj).to_hash.to_json
          object['json'] = json
          @client.insert(:Objects, sha, object)      
        elsif obj.type.to_s == 'tag'
          @client.insert(:Objects, sha, object)      
        elsif obj.type.to_s == 'blob'
          # TODO check to see if this object is small enough, otherwise split it up
          @client.insert(:Objects, sha, object)      
        end
      end      
      
    end

    def update_refs
      heads = {}
      tags = {}
      remotes = {}
      @grit.heads.each { |h| heads[h.name] = h.commit.id }
      @grit.tags.each { |h| tags[h.name] = h.commit.id }
      @grit.remotes.each { |h| remotes[h.name] = h.commit.id }
      
      # TODO: master
      refs = {}
      refs['heads']   = heads   if heads.size > 0
      refs['tags']    = tags    if tags.size > 0
      refs['remotes'] = remotes if remotes.size > 0
      refs['meta']    = {'HEAD' => @grit.head.commit} if @grit.head
      @client.remove(:Repositories, @repo_handle)
      @client.insert(:Repositories, @repo_handle, refs)
    end
    
    def update_repo_info
      @client.insert(:Repositories, '__main_listing__', {@repo_handle => {'updated' => Time.now.to_i.to_s}})
    end

  end
end