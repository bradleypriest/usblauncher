require "net/http"
require "./launcher"
require "json"

$JENKINS_SERVER = "hudson.localist.co.nz"
$LAUNCHER = Launcher.new

class JenkinsWatcher

  def self.init
    new
  end

  def initialize
    @failed_jobs = []
    poll
  end

  def poll
    result = Net::HTTP.get($JENKINS_SERVER, "/api/json")
    jobs = JSON.parse(result)['jobs']
    puts jobs.to_s
    jobs.each do |job|
      if job['color'] =~ /blue/
        @failed_jobs.delete(job['name'])
      else
        process_failure(job)
      end
    end
    puts "."
    sleep(60)
    poll
  end

  def process_failure(job)
    unless @failed_jobs.include?(job['name'])
      user = get_jenkins_user(job['name'])
      $LAUNCHER.attack(user)
      @failed_jobs << job['name']
      print "#{job['name']} was broken by #{job['user']}"
    end
  end

  def get_jenkins_user(job_name)
    result = Net::HTTP.get( $JENKINS_SERVER , "/job/" + job_name + "/lastFailedBuild/changes" )
    user = result.match('"/user/([^/"]+)')[1].downcase.split("%20").first
  end

end