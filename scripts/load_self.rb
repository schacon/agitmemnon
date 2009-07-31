require '../lib/agitmemnon'

a = Agitmemnon::Repo.new('agitmemnon', '../.')
pp a

a.update