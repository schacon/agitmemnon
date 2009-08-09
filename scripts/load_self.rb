require '../lib/agitmemnon'

#a = Agitmemnon::Repo.new('agitmemnon', '../.')
#a.update

a = Agitmemnon::Repo.new('fuzed', '/Users/schacon/projects/fuzed')
#a = Agitmemnon::Repo.new('testing', '/tmp/test')
pp a
a.update
