require '../lib/agitmemnon'

name = ARGV[0]
path = ARGV[1]
a = Agitmemnon::Repo.new(name, path)
pp a
a.update(true)

