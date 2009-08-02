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
    
    def tree(rev = nil)
      rev = self.head[1] if !rev
      commit = @client.get(:Objects, rev, 'json')
      commit = JSON.parse(commit)
      tree_sha = commit['tree']
      tree = @client.get(:Objects, tree_sha, 'json')
      tree = JSON.parse(tree).sort
    end
    
    def log(options = {})
      options = {:count => 30}.merge(options)
      
      shas = [self.head[1]]
      commits = []      
      while (sha = shas.pop) && (commits.size < options[:count])
        commit = @client.get(:Objects, sha, 'json')
        commit = JSON.parse(commit)
        commits << [sha, commit]
        shas << commit['parents'] if commit['parents']
        shas = shas.flatten
      end
      commits
    end
        
  end
end