module Agitmemnon
  class Client

    class Commit
      attr_reader :sha
      def initialize(client, sha)
        @client = client
        @sha = sha
        @data = JSON.parse(@client.get(:Objects, sha, 'json'))
      end
      def short_message
        @data['message'][0, 100]
      end
      def author_info
         m, name, email, time = *@data['author'].match(/(.*) <(.+?)> (.+?) (.*)/)
         [name, email, Time.at(time.to_i)]
      end
      def author_email
        @author_info ||= self.author_info
        @author_info[1]
      end
      def author_time
        @author_info ||= self.author_info
        @author_info[2]
      end
      def tree
        @tree = JSON.parse(@client.get(:Objects, @data['tree'], 'json'))
      end
      def readme
        @tree ||= tree
        if readme_sha = tree['README']['sha']
          return Zlib::Inflate.inflate(Base64.decode64(@client.get(:Objects, readme_sha, 'data')))
        end
      end
    end

    attr_accessor :client, :repo_handle

    def initialize(repo_handle)
      raise if repo_handle == '__main_listing__'  # reserved word
      @client = Cassandra.new(Agitmemnon.table)
      @repo_handle = repo_handle
    end

    def self.repo_list
      client = Cassandra.new(Agitmemnon.table)
      client.get(:Repositories, '__main_listing__')
    end

    def refs
      @client.get(:Repositories, @repo_handle)
    end

    def head
      head = self.refs['meta']['HEAD']
      head = self.refs['heads'].to_a.first[1] if !head
      head
    end

    def head_commit
      Client::Commit.new(@client, head)
    end

    def get(sha)
      @client.get(:Objects, sha)
    end

    def diff(sha)
      client.get(:CommitDiffs, @repo_name, sha)
    end

    def tree(rev = nil)
      rev = self.head if !rev
      commit = @client.get(:Objects, rev, 'json')
      commit = JSON.parse(commit)
      tree_sha = commit['tree']
      tree = @client.get(:Objects, tree_sha, 'json')
      tree = JSON.parse(tree).sort
    end

    def log(options = {})
      options = {:count => 30}.merge(options)

      shas = [self.head]
      commits = []
      while (sha = shas.pop) && (commits.size < options[:count])
        if commit = @client.get(:Objects, sha.to_s, 'json')
          commit = JSON.parse(commit)
          commits << [sha, commit]
          shas << commit['parents'] if commit['parents']
          shas = shas.flatten
        end
      end
      commits
    end

  end
end

