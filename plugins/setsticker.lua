local function tosticker(msg, success, result)
  local receiver = get_receiver(msg)
  if success then
    local file = 'sticker.webp'
    print('File downloaded to:', result)
    os.rename(result, file)
    print('File moved to:', file)
    send_document(get_receiver(msg), file, ok_cb, false)
	send_large_msg(receiver, 'درست شدددد', ok_cb, false)
    redis:del("photo:تبدیل")
  else
    print('Error downloading: '..msg.id)
    send_large_msg(receiver, 'Failed, please try again!', ok_cb, false)
  end
end
local function run(msg,matches)
    local receiver = get_receiver(msg)
    local group = msg.to.id
    if msg.media then
       if msg.media.type == 'به استیکر' and redis:get("photo:تبدیل") then
        if redis:get("photo:تبدیل") == 'waiting' then
          load_photo(msg.id, tosticker, msg)
        end
       end
    end
    if matches[1]:lower() == "تبدیل" and is_sudo(msg) then
     redis:set("photo:تبدیل", "waiting")
     return 'عکسو بده تبدیل کنم :)'
    end
	if matches[1]:lower() == 'تبدیل به استیکر' then --[[Your bot name]]
	send_document(get_receiver(msg), "sticker.webp", ok_cb, false)
end
end
return {
  patterns = {
 "^به استیکر$",
 "^تبدیل$",
 "^تبدیل به استیکر",
 "%[(photo)%]",
  },
  run = run,
}
