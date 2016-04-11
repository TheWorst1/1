s (12 sloc) 194 Bytes
do

function run(msg, matches)
send_document(get_receiver(msg), "/root/robot/sticker.webp", ok_cb, false)
end

return {
patterns = {
"^(سیو)$",
"^(سیوو)$",

},
run = run
}

end
