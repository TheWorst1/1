local function run(msg, matches)

  local receiver = get_receiver(msg)
    if matches[1] == "اسپم" and is_admin(msg) then
    local num = matches[2]
     local text = matches[3]
        for i=1,num do
            send_large_msg(receiver, text)
        end
  end
end
 
return {
  patterns = {
  "^اسپم (%d+) (.*)$",
  "^اسپم (%d+) (.*)$",
  },
  run = run,
}
