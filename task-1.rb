# Deoptimized version of homework task

require 'json'
require 'pry'
require 'date'
require 'minitest/autorun'
require 'ruby-prof'
require 'stackprof'
require 'set'

def parse_user(user)
  parsed_result = {
    'id' => user[1],
    'first_name' => user[2],
    'last_name' => user[3],
    'age' => user[4],
  }
end

def parse_session(session)
  parsed_result = {
    'user_id' => session[1],
    'session_id' => session[2],
    'browser' => session[3].upcase,
    'time' => session[4],
    'date' => session[5],
  }
end

def collect_stats_from_users(report, user)
  user_key = "#{user[:attributes]['first_name']}" + ' ' + "#{user[:attributes]['last_name']}"
  report['usersStats'][user_key] ||= {}
  report['usersStats'][user_key] = report['usersStats'][user_key].merge(yield(user))
end

def work
  # Отчёт в json
  #   - Сколько всего юзеров +
  #   - Сколько всего уникальных браузеров +
  #   - Сколько всего сессий +
  #   - Перечислить уникальные браузеры в алфавитном порядке через запятую и капсом +
  #
  #   - По каждому пользователю
  #     - сколько всего сессий +
  #     - сколько всего времени +
  #     - самая длинная сессия +
  #     - браузеры через запятую +
  #     - Хоть раз использовал IE? +
  #     - Всегда использовал только Хром? +
  #     - даты сессий в порядке убывания через запятую +

  users = []
  sessions = []
  report = {}
  report['totalUsers'] = 0
  report['uniqueBrowsersCount'] = 0
  report['totalSessions'] = 0
  browsers = {}
  grouped_sessions = {}

  IO.foreach('data_1000000.txt') do |line|
    cols = line.strip.split(',')

    if cols[0] == 'user'
      users.push(parse_user(cols))
      report['totalUsers'] += 1
    end

    if cols[0] == 'session'
      session = parse_session(cols)
      sessions.push(session)
      grouped_sessions[cols[1]] ||= []
      grouped_sessions[cols[1]] << session
      report['totalSessions'] += 1
      browsers[cols[3]] = cols[3]
    end
  end

  uniqueBrowsers = browsers.keys
  # grouped_sessions = sessions.group_by {|session| session['user_id']}
  report['uniqueBrowsersCount'] = uniqueBrowsers.count
  report['allBrowsers'] = sessions.map { |s| s['browser'] }.sort.uniq.join(',')

  # Статистика по пользователям
  users_objects = []
  report['usersStats'] = {}

  users.each do |user|
    # user_object = User.new(attributes: user, sessions: grouped_sessions[user['id']])
    user_object = { attributes: user, sessions: grouped_sessions[user['id']] }
    collect_stats_from_users(report, user_object) do |user|
      browsers = user[:sessions].map {|s| s['browser']}
      userIE = browsers.any? { |b| b =~ /INTERNET EXPLORER/ }

      { 'sessionsCount' => user[:sessions].count,
        'totalTime' => user[:sessions].sum { |session| session['time'].to_i }.to_s + ' min.',
        'longestSession' => user[:sessions].map {|s| s['time']}.map {|t| t.to_i}.max.to_s + ' min.',
        'browsers' => browsers.map {|b| b}.sort.join(', '),
        'usedIE' => userIE,
        'alwaysUsedChrome' => userIE ? false : browsers.all? { |b| b =~ /CHROME/ },
        'dates' => user[:sessions].map{|s| s['date'].strip}.sort_by { |s| Date.strptime(s, '%Y-%m-%d') }.reverse }
    end
  end

  File.write('result.json', "#{report.to_json}\n")
end

# GC.disable
RubyProf.measure_mode = RubyProf::WALL_TIME

result = RubyProf.profile do
  beginning_time = Time.now
  work
  end_time = Time.now
  puts "Time elapsed #{(end_time - beginning_time)}"
end

printer = RubyProf::GraphHtmlPrinter.new(result)
printer.print(File.open("ruby_prof_reports/graph.html", "w+"))




# GC.disable
# profile = StackProf.run(mode: :wall, raw: true) do
#   work
# end

# File.write('stackprof_reports/stackprof.json', JSON.generate(profile))




# class TestMe < Minitest::Test
#   def setup
#     File.write('result.json', '')
#     File.write('data.txt',
# 'user,0,Leida,Cira,0
# session,0,0,Safari 29,87,2016-10-23
# session,0,1,Firefox 12,118,2017-02-27
# session,0,2,Internet Explorer 28,31,2017-03-28
# session,0,3,Internet Explorer 28,109,2016-09-15
# session,0,4,Safari 39,104,2017-09-27
# session,0,5,Internet Explorer 35,6,2016-09-01
# user,1,Palmer,Katrina,65
# session,1,0,Safari 17,12,2016-10-21
# session,1,1,Firefox 32,3,2016-12-20
# session,1,2,Chrome 6,59,2016-11-11
# session,1,3,Internet Explorer 10,28,2017-04-29
# session,1,4,Chrome 13,116,2016-12-28
# user,2,Gregory,Santos,86
# session,2,0,Chrome 35,6,2018-09-21
# session,2,1,Safari 49,85,2017-05-22
# session,2,2,Firefox 47,17,2018-02-02
# session,2,3,Chrome 20,84,2016-11-25
# ')
#   end

#   def test_result
#     work
#     expected_result = '{"totalUsers":3,"uniqueBrowsersCount":14,"totalSessions":15,"allBrowsers":"CHROME 13,CHROME 20,CHROME 35,CHROME 6,FIREFOX 12,FIREFOX 32,FIREFOX 47,INTERNET EXPLORER 10,INTERNET EXPLORER 28,INTERNET EXPLORER 35,SAFARI 17,SAFARI 29,SAFARI 39,SAFARI 49","usersStats":{"Leida Cira":{"sessionsCount":6,"totalTime":"455 min.","longestSession":"118 min.","browsers":"FIREFOX 12, INTERNET EXPLORER 28, INTERNET EXPLORER 28, INTERNET EXPLORER 35, SAFARI 29, SAFARI 39","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-09-27","2017-03-28","2017-02-27","2016-10-23","2016-09-15","2016-09-01"]},"Palmer Katrina":{"sessionsCount":5,"totalTime":"218 min.","longestSession":"116 min.","browsers":"CHROME 13, CHROME 6, FIREFOX 32, INTERNET EXPLORER 10, SAFARI 17","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-04-29","2016-12-28","2016-12-20","2016-11-11","2016-10-21"]},"Gregory Santos":{"sessionsCount":4,"totalTime":"192 min.","longestSession":"85 min.","browsers":"CHROME 20, CHROME 35, FIREFOX 47, SAFARI 49","usedIE":false,"alwaysUsedChrome":false,"dates":["2018-09-21","2018-02-02","2017-05-22","2016-11-25"]}}}' + "\n"
#     assert_equal expected_result, File.read('result.json')
#   end
# end







# printer = RubyProf::FlatPrinter.new(result)
# printer.print(File.open("ruby_prof_reports/flat.txt", "w+"))

# work