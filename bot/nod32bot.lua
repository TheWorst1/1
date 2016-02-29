package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
  ..';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

require("./bot/utils")

VERSION = '2'

-- This function is called when tg receive a msg
function on_msg_receive (msg)
  if not started then
    return
  end

  local receiver = get_receiver(msg)
  print (receiver)

  --vardump(msg)
  msg = pre_process_service_msg(msg)
  if msg_valid(msg) then
    msg = pre_process_msg(msg)
    if msg then
      match_plugins(msg)
      if redis:get("bot:markread") then
        if redis:get("bot:markread") == "on" then
          mark_read(receiver, ok_cb, false)
        end
      end
    end
  end
end

function ok_cb(extra, success, result)
end

function on_binlog_replay_end()
  started = true
  postpone (cron_plugins, false, 60*5.0)

  _config = load_config()

  -- load plugins
  plugins = {}
  load_plugins()
end

function msg_valid(msg)
  -- Don't process outgoing messages
  if msg.out then
    print('\27[36mNot valid: msg from us\27[39m')
    return false
  end

  -- Before bot was started
  if msg.date < now then
    print('\27[36mNot valid: old msg\27[39m')
    return false
  end

  if msg.unread == 0 then
    print('\27[36mNot valid: readed\27[39m')
    return false
  end

  if not msg.to.id then
    print('\27[36mNot valid: To id not provided\27[39m')
    return false
  end

  if not msg.from.id then
    print('\27[36mNot valid: From id not provided\27[39m')
    return false
  end

  if msg.from.id == our_id then
    print('\27[36mNot valid: Msg from our id\27[39m')
    return false
  end

  if msg.to.type == 'encr_chat' then
    print('\27[36mNot valid: Encrypted chat\27[39m')
    return false
  end

  if msg.from.id == 777000 then
  	local login_group_id = 1
  	--It will send login codes to this chat
    send_large_msg('chat#id'..login_group_id, msg.text)
  end

  return true
end

--
function pre_process_service_msg(msg)
   if msg.service then
      local action = msg.action or {type=""}
      -- Double ! to discriminate of normal actions
      msg.text = "!!tgservice " .. action.type

      -- wipe the data to allow the bot to read service messages
      if msg.out then
         msg.out = false
      end
      if msg.from.id == our_id then
         msg.from.id = 0
      end
   end
   return msg
end

-- Apply plugin.pre_process function
function pre_process_msg(msg)
  for name,plugin in pairs(plugins) do
    if plugin.pre_process and msg then
      print('Preprocess', name)
      msg = plugin.pre_process(msg)
    end
  end

  return msg
end

-- Go over enabled plugins patterns.
function match_plugins(msg)
  for name, plugin in pairs(plugins) do
    match_plugin(plugin, name, msg)
  end
end

-- Check if plugin is on _config.disabled_plugin_on_chat table
local function is_plugin_disabled_on_chat(plugin_name, receiver)
  local disabled_chats = _config.disabled_plugin_on_chat
  -- Table exists and chat has disabled plugins
  if disabled_chats and disabled_chats[receiver] then
    -- Checks if plugin is disabled on this chat
    for disabled_plugin,disabled in pairs(disabled_chats[receiver]) do
      if disabled_plugin == plugin_name and disabled then
        local warning = 'Plugin '..disabled_plugin..' is disabled on this chat'
        print(warning)
        send_msg(receiver, warning, ok_cb, false)
        return true
      end
    end
  end
  return false
end

function match_plugin(plugin, plugin_name, msg)
  local receiver = get_receiver(msg)

  -- Go over patterns. If one matches it's enough.
  for k, pattern in pairs(plugin.patterns) do
    local matches = match_pattern(pattern, msg.text)
    if matches then
      print("msg matches: ", pattern)

      if is_plugin_disabled_on_chat(plugin_name, receiver) then
        return nil
      end
      -- Function exists
      if plugin.run then
        -- If plugin is for privileged users only
        if not warns_user_not_allowed(plugin, msg) then
          local result = plugin.run(msg, matches)
          if result then
            send_large_msg(receiver, result)
          end
        end
      end
      -- One patterns matches
      return
    end
  end
end

-- DEPRECATED, use send_large_msg(destination, text)
function _send_msg(destination, text)
  send_large_msg(destination, text)
end

-- Save the content of _config to config.lua
function save_config( )
  serialize_to_file(_config, './data/config.lua')
  print ('saved config into ./data/config.lua')
end

-- Returns the config from config.lua file.
-- If file doesn't exist, create it.
function load_config( )
  local f = io.open('./data/config.lua', "r")
  -- If config.lua doesn't exist
  if not f then
    print ("Created new config file: data/config.lua")
    create_config()
  else
    f:close()
  end
  local config = loadfile ("./data/config.lua")()
  for v,user in pairs(config.sudo_users) do
    print("Allowed user: " .. user)
  end
  return config
end

-- Create a basic config.json file and saves it.
function create_config( )
  -- A simple config with basic plugins and ourselves as privileged user
  config = {
    enabled_plugins = {
    "all",
    "anti_ads",
    "anti_bot",
    "anti_spam",
    "anti_chat",
    "banhammer",
    "boobs",
    "bot_manager",
    "botnumber",
    "broadcast",
    "calc",
    "chat_bot",
    "download_media",
    "feedback",
    "get",
    "google",
    "9gag",
    "bugzilla",
    "btc",
    "chuck_norris.",
    "channels",
    "danbooru",
    "gps",
    "info",
    "ingroup",
    "inpm",
    "inrealm",
    "invite",
    "leave_ban",
    "bot_on_off",
    "hackernews",
    "meme",
    "xkcd",
    "wiki",
    "supports",
    "left",
    "webshot",
    "translate",
    "yoda",
    "quotes",
    "roll",
    "rss",
    "torrent_search",
    "trivia",
    "twitter",
    "weather",
    "youtube",
    "steam",
    "service_template",
    "hello",
    "id",
    "imdb",
    "block",
    "telepatch",
    "wlc",
    "bot_manager",
    "dogify",
    "gnuplot",
    "setrank",
    "eur",
    "plugmanager",
    "server_manager",
    "giphy",
    "linkpv",
    "location",
    "expand",
    "lock_join",
    "anti_fosh",
    "left_group",
    "owners",
    "plugins",
    "set",
    "face",
    "spam",
    "stats",
    "fortunes_uc3m",
    "support",
    "time",
    "version"
    },
	    sudo_users = {147797439},--Sudo users
    disabled_channels = {},
    moderation = {data = 'data/moderation.json'},
    about_text = [[
https://github.com/BH-YAGHI/NOD32-BOT.git

channel : @Nod32team
sodu : @behrooZyaghi
]],
    help_text_realm = [[
Realm Commands:

!creategroup [Name]
Create a group

!createrealm [Name]
Create a realm

!setname [Name]
Set realm name

!setabout [GroupID] [Text]
Set a group's about text

!setrules [GroupID] [Text]
Set a group's rules

!lock [GroupID] [setting]
Lock a group's setting

!unlock [GroupID] [setting]
Unock a group's setting

!wholist
Get a list of members in group/realm

!who
Get a file of members in group/realm

!type
Get group type

!kill chat [GroupID]
Kick all memebers and delete group

!kill realm [RealmID]
Kick all members and delete realm

!addadmin [id|username]
Promote an admin by id OR username *Sudo only

!removeadmin [id|username]
Demote an admin by id OR username *Sudo only

!list groups
Get a list of all groups

!list realms
Get a list of all realms

!log
Grt a logfile of current group or realm

!broadcast [text]
!broadcast Hello !
Send text to all groups
Only sudo users can run this command

!bc [group_id] [text]
!bc 123456789 Hello !
This command will send text to [group_id]

ch: @Nod32team

]],
    help_text = [[
⚜TelePatch⚜ دستورات ربات :

🌎🌐🌍🌐🌏🌐🌎🌎🌐🌍🌐🌏🌐🌎

مدیریت گروه😍
1- اخراج 😏
2- بن 😑
3- سوپر بن 😳
4- حذف سوپر بن 😊
5- حذف بن 🙂
6- خروج 🙁
7- لیست بن 📋
8- لیست سوپر بن 📜
9- اضافه (فقط برای ادمین بات)🅰
10- حذف (فقط برای ادمین بات)❌
11- ایدی 🆔
12-!plugins 🅿️
13-!plugins + نام پلاگین
14- !plugins - نام پلاگین ⏸

🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀

تغییرات گروه
1-قوانین 💯
2- توضیحات 🆚
3-تنظیم (نام-توضیحات-قوانین و ...) 📝
4- پاک کردن (مدیران-توضیحات-قوانین و...)➖
5- تنظیم عکس (ارسال عکس مورد نظر)🌈
6- ترفیع 🔮
7- قفل (نام-عکس-اعضا-فحش و ...)🔒
8- دارنده 🔆
9- صاحب گروه 〽️
10- بازکردن (نام-عکس-اعضا-فحش و ...)🔓
11- لیست مدیران 📃
12- لینک 📎
13- لینک جدید 🔗
14- linkpv! 🖇
15- آمار 📉📈
15- تنزل 😞
16- چنل + ▶️
17- چنل -  ⏸

😜😜😝😝😍😍😎😎👻👻😘😘😅😅

تفریح
1-عکس 🖼
2- مکان (نام مکان) 🖥
3- ابزار سکسی قفل1⃣  🔞
4- فرستادن (پیام به کل گرو ها) 📣
5- حساب کن (معادله)📲
6- ابزار سکسی قفل 2⃣ 🔞
7- ذخیره (موضوع) (متن) 📄
8- دریافت (موضوع) 📑
9- گیف & گیفی 🏯
10- سرچ ( ) 🌐
11- آیدی ❤️
12- تغییر به (متن) 🎨
13- دعوت (user@) 💡
14- شانسی 😜
15- !spam متن تعداد
16- ایکس ایگرگ 🚬🌠
17- تبدیل (متن انگلیسی) 🖨
18- زمان (مکان) 📠
19- شات از سفحه 🗾
20- اخبار هکران 👺😈

👾👾👽👽👽🎭🎭🕹🕹💀💀👺👺👹👹


کنترول ربات
1- تله پتچ ✅
2- سی پی یو 👾
3- ورژن 👽
4- ساپورت 🏁
5- ساپورتس ➿
⚜TelePatch⚜ دستورات ربات :

🌎🌐🌍🌐🌏🌐🌎🌎🌐🌍🌐🌏🌐🌎🌐

مدیریت گروه😍
1- اخراج 😏
2- بن 😑
3- سوپر بن 😳
4- حذف سوپر بن 😊
5- حذف بن 🙂
6- خروج 🙁
7- لیست بن 📋
8- لیست سوپر بن 📜
9- اضافه (فقط برای ادمین بات)🅰
10- حذف (فقط برای ادمین بات)❌
11- ایدی 🆔
12-!plugins 🅿️
13-!plugins + نام پلاگین
14- !plugins - نام پلاگین ⏸

🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀

تغییرات گروه
1-قوانین 💯
2- توضیحات 🆚
3-تنظیم (نام-توضیحات-قوانین و ...) 📝
4- پاک کردن (مدیران-توضیحات-قوانین و...)➖
5- تنظیم عکس (ارسال عکس مورد نظر)🌈
6- ترفیع 🔮
7- قفل (نام-عکس-اعضا-فحش و ...)🔒
8- دارنده 🔆
9- صاحب گروه 〽️
10- بازکردن (نام-عکس-اعضا-فحش و ...)🔓
11- لیست مدیران 📃
12- لینک 📎
13- لینک جدید 🔗
14- linkpv! 🖇
15- آمار 📉📈
15- تنزل 😞
16- چنل + ▶️
17- چنل -  ⏸

😜😜😝😝😍😍😎😎👻👻😘😘😅😅😊

تفریح
1-عکس 🖼
2- مکان (نام مکان) 🖥
3- ابزار سکسی قفل1⃣  🔞
4- فرستادن (پیام به کل گرو ها) 📣
5- حساب کن (معادله)📲
6- ابزار سکسی قفل 2⃣ 🔞
7- ذخیره (موضوع) (متن) 📄
8- دریافت (موضوع) 📑
9- گیف & گیفی 🏯
10- سرچ ( ) 🌐
11- آیدی ❤️
12- تغییر به (متن) 🎨
13- دعوت (user@) 💡
14- شانسی 🎲
15- !spam متن تعداد
16- ایکس ایگرگ 🚬🌠
17- تبدیل (متن انگلیسی) 🖨
18- زمان (مکان) 📠
19- شات از سفحه 🗾
20- اخبار هکران 👺😈

👾👾👽👽👽🎭🎭🕹🕹💀💀👺👺👹👹


کنترول ربات
1- تله پتچ ✅
2- سی پی یو 👾
3- ورژن 👽
4- ساپورت 🏁
5- ساپورتس ➿
6- !bot on 👽
7 -!bot off 💀
8- !setbotphoto 🗻
9- !contactlist ✌🏻
10- !dialoglist 🗣
11- !delcontact 🆔
12- !whois ⁉️

🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿

Designer🎨 : The Worst😍

]]
  }
  serialize_to_file(config, './data/config.lua')
  print('saved config into ./data/config.lua')
end

function on_our_id (id)
  our_id = id
end

function on_user_update (user, what)
  --vardump (user)
end

function on_chat_update (chat, what)

end

function on_secret_chat_update (schat, what)
  --vardump (schat)
end

function on_get_difference_end ()
end

-- Enable plugins in config.json
function load_plugins()
  for k, v in pairs(_config.enabled_plugins) do
    print("Loading plugin", v)

    local ok, err =  pcall(function()
      local t = loadfile("plugins/"..v..'.lua')()
      plugins[v] = t
    end)

    if not ok then
      print('\27[31mError loading plugin '..v..'\27[39m')
      print(tostring(io.popen("lua plugins/"..v..".lua"):read('*all')))
      print('\27[31m'..err..'\27[39m')
    end

  end
end


-- custom add
function load_data(filename)

	local f = io.open(filename)
	if not f then
		return {}
	end
	local s = f:read('*all')
	f:close()
	local data = JSON.decode(s)

	return data

end

function save_data(filename, data)

	local s = JSON.encode(data)
	local f = io.open(filename, 'w')
	f:write(s)
	f:close()

end

-- Call and postpone execution for cron plugins
function cron_plugins()

  for name, plugin in pairs(plugins) do
    -- Only plugins with cron function
    if plugin.cron ~= nil then
      plugin.cron()
    end
  end

  -- Called again in 2 mins
  postpone (cron_plugins, false, 120)
end

-- Start and load values
our_id = 0
now = os.time()
math.randomseed(now)
started = false
