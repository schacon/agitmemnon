module Agitmemnon
  class Client
    
    def initialize(repo_handle)
      raise if repo_handle == '__main_listing__'  # reserved word      
      @client = CassandraClient.new(Agitmemnon.table)
      @repo_handle = repo_handle
    end
    
    def self.repo_list
      client = CassandraClient.new(Agitmemnon.table)
      client.get(:Repositories, '__main_listing__')
    end
    
    def refs
      @client.get(:Repositories, @repo_handle)
    end
    
    def head
      # TODO: record the HEAD
      self.refs['heads'].to_a.first
    end
    
    def log(options = {})
      options = {:count => 10}.merge(options)
      
      shas = [self.head[1]]
      
      commits = []      
      while (sha = shas.pop)
        pp sha
        commit = @client.get(:Objects, sha, 'json')
        puts commit
        commit = JSON.parse(commit)
        commits << [sha, commit]
        shas << commit['parents'] if commit['parents']
        shas = shas.flatten
      end
      pp commits
      commits
    end
        
  end
end