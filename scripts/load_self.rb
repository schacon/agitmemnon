require '../lib/agitmemnon'

#a = Agitmemnon::Repo.new('agitmemnon', '../.')
#a.update

#a = Agitmemnon::Repo.new('cassandra', '/opt/cassandra/cassandra')
a = Agitmemnon::Repo.new('fuzed2', '/Users/schacon/projects/fuzed2')
#a = Agitmemnon::Repo.new('git', '/Users/schacon/projects/git')
#a = Agitmemnon::Repo.new('testing', '/tmp/test')
pp a
a.update(false)
