web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
sidekiq: bundle exec sidekiq -C ./config/sidekiq.yml
cpw: /bin/bash --login -c 'cd /Users/juergen/work/vzo/vz-cpw && rvm gemset use vz-cpw && bundle exec shoryuken -r cpw.rb -C config/shoryuken.yml'
