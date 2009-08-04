require '../lib/agitmemnon'
require 'benchmark'

repo = "/Users/schacon/projects/fuzed"

grit = Grit::Repo.new(repo)
agit = Agitmemnon::Client.new('fuzed')

n = 10
r = 'c701f00be4fedcfe41016e415685d4464a0172d2'

Dir.chdir(repo) do
  Benchmark.bm do |x|
    x.report("grit log")  do
      n.times { grit.log('master', nil, {:max_count => 100} ) }
    end

    x.report("agit log")  do
      n.times { agit.log(:count => 100) }
    end

    x.report("agit get")  do
      n.times { 3.times { agit.client.get(:CommitTree, 'fuzed') } }
    end

    x.report("grit cat-file")  do
      n.times { `git cat-file -p #{r}` }
    end

    x.report("agit cat-file")  do
      n.times { agit.client.get(:Objects, r) }
    end

  end
end