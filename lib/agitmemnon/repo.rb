module Agitmemnon
  class Repo

    attr_accessor :repo_handle, :grit, :client

    def initialize(repo_handle, path)
      raise if repo_handle == '__main_listing__'  # reserved word      
      @client = CassandraClient.new(Agitmemnon.table)
      @repo_handle = repo_handle
      @grit = Grit::Repo.new(path)
    end

    def update
      update_objects
      update_commit_cache
      update_refs
      update_repo_info
    end

    protected

    def update_objects
      # get current refs
      current_refs = @grit.refs.map { |h| h.commit.id }
      cass_refs = [] # TODO
      
      # find all commits between that ref and the heads
      have_refs = (cass_refs - current_refs).map { |r| "^#{r}"}.join(' ')
      need_refs = (current_refs - cass_refs).join(' ')
      objects = @grit.objects("#{need_refs} #{have_refs}")

      # foreach object
      objects.each do |sha|
        obj = @grit.git.ruby_git.get_raw_object_by_sha1(sha)
        puts "#{obj.type}:#{obj.content.size}:#{sha}"
        object = {'type' => obj.type, 'size' => obj.content.length, 'data' => Base64.encode64(Zlib::Deflate.deflate(obj.content)) }
        if obj.type.to_s == 'commit'
          json = Grit::GitRuby::GitObject.from_raw(obj).to_hash.to_json
          object['json'] = json
        end
        @client.insert(:Objects, sha, object)      
      end
    end

    def update_commit_cache
      #gh.insert(:CommitTree, prname, {'revlist' => commit_list.join("\n")})
      #puts counter
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
      @client.remove(:Repositories, @repo_handle)
      @client.insert(:Repositories, @repo_handle, refs)
    end
    
    def update_repo_info
      @client.insert(:Repositories, '__main_listing__', {@repo_handle => {'updated' => Time.now.to_i}})
    end

  end
end