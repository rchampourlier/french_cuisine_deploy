Capistrano::Configuration.instance.load do

  namespace :db do
    task :restore, :roles => :db do
      db.pg.restore
      db.mongo.restore
    end

    task :push, :roles => :db, :on_error => :continue do
      db.pg.push
      db.mongo.push
    end
  end
end