require '../lib/agitmemnon'

#a = Agitmemnon::Repo.new('agitmemnon', '../.')
#a.update

#a = Agitmemnon::Repo.new('cassandra', '/opt/cassandra/cassandra')
#a = Agitmemnon::Repo.new('fuzed', '/home/schacon/projects/fuzed')
a = Agitmemnon::Repo.new('schacon/grit', '/home/schacon/projects/grit')
#a = Agitmemnon::Repo.new('git', '/Users/schacon/projects/git')
#a = Agitmemnon::Repo.new('testing', '/tmp/test')
pp a
a.update(true)

