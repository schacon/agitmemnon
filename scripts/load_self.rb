require '../lib/agitmemnon'

#a = Agitmemnon::Repo.new('agitmemnon', '../.')
#a.update

a = Agitmemnon::Repo.new('fuzed', '/Users/schacon/projects/fuzed')
pp a
a.update
