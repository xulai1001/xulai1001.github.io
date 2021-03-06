require "sqlite3"
require "mechanize"
require "json"

$db = SQLite3::Database.new "../db/db.sqlite3"
$api_root = "http://act.ff.sdo.com/20170824UploadImg/Server/ImgService.ashx"
$m = Mechanize.new

def api_call(meth)
    ret = $m.post "#{$api_root}?method=#{meth}"
    h = JSON.parse ret.body
    h["Attach"]
end

def image_list
    l = JSON.parse api_call("imagelist")
    ret = {}
    l.each {|item| ret[item["Id"].to_i] = item}
    ret
end

def insert(v)
    ["Id", "AreaId", "GroupId", "CharacterId", "RoleId"].each do |k|
        v[k] = v[k].to_i
    end
    v.keys.each {|k| v[k] = (v[k].is_a?(String)? "\"#{v[k]}\"" : v[k])}
    values=%w(Id AreaId AreaName GroupId GroupName CharacterId
                RoleId RoleName BigImage SmallImage).map{|k|v[k]}.join(",")
    # puts values
    $db.execute "insert or replace into ffwall values (#{values})"
end

def load_id
    ($db.execute "select Id from ffwall").flatten
end

$ids = load_id

loop do
    list = image_list
    list.keys.select {|k| !$ids.include?(k)}.each {|k|
        insert(list[k])
        $ids << k
        puts "+ #{list[k]["GroupName"]}, #{list[k]["RoleName"]}"
    }
    puts "------------------"
    sleep 8
end
