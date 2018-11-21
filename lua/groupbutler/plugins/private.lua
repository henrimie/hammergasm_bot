local config = require "groupbutler.config"
local locale = require "groupbutler.languages"
local i18n = locale.translate
local api_err = require "groupbutler.api_errors"

local _M = {}

function _M:new(update_obj)
	local plugin_obj = {}
	setmetatable(plugin_obj, {__index = self})
	for k, v in pairs(update_obj) do
		plugin_obj[k] = v
	end
	return plugin_obj
end

local function bot_version()
	if not config.commit or (config.commit):len() ~= 40 then
		return i18n("unknown")
	end
	return ("[%s](%s/commit/%s)"):format(string.sub(config.commit, 1, 7), config.source_code, config.commit)
end

local strings = {
	about = i18n([[This bot is based on [GroupButler](https://github.com/group-butler/GroupButler) (AKA @GroupButler_bot), a multipurpose Lua bot.
Hammergasm wouldn't exist without it.

You can contact the owners of this bot using the /groups command.

Bot version: %s
*Some useful links:*]]):format(bot_version())
}

local function do_keyboard_credits(self)
	local bot = self.bot
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{text = i18n("Channel"), url = 'https://telegram.me/'..config.channel:gsub('@', '')},
			{text = i18n("GitHub"), url = config.source_code},
			{text = i18n("Rate me!"), url = 'https://telegram.me/storebot?start='..bot.username},
		},
		{
			{text = i18n("👥 Groups"), callback_data = 'private:groups'}
		}
	}
	return keyboard
end

function _M:onTextMessage(blocks)
	local api = self.api
	local msg = self.message

	if msg.chat.type ~= 'private' then return end

	if blocks[1] == 'ping' then
		api:sendMessage(msg.from.id, i18n("Pong!"), "Markdown")
	end
	if blocks[1] == 'echo' then
		local ok, err = api:sendMessage(msg.chat.id, blocks[2], "Markdown")
		if not ok then
			api:sendMessage(msg.chat.id, api_err.trans(err), "Markdown")
		end
	end
	if blocks[1] == 'about' then
		local keyboard = do_keyboard_credits(self)
		api:sendMessage(msg.chat.id, strings.about, "Markdown", true, nil, nil, keyboard)
	end
	if blocks[1] == 'group' then
		if config.help_group and config.help_group ~= '' then
			api:sendMessage(msg.chat.id,
				i18n("Cryptogasmic groups and channels:\n[Chat Group](https://t.me/cryptogasmic1)\n[Social Group](https://t.me/joinchat/Gp0E6E6aKGVvFMNW7TA_6w)\n[Krypto's Updates](https://t.me/kryptogasmic)\n[Crypto News](https://t.me/Cryptogasmicnews)"), "Markdown")
		end
	end
end

function _M:onCallbackQuery(blocks)
	local api = self.api
	local msg = self.message

	if blocks[1] == 'about' then
		local keyboard = do_keyboard_credits(self)
		api:editMessageText(msg.chat.id, msg.message_id, nil, strings.about, "Markdown", true, keyboard)
	end
	if blocks[1] == 'group' then
		if config.help_group and config.help_group ~= '' then
			local markup = {inline_keyboard={{{text = i18n('🔙 back'), callback_data = 'fromhelp:about'}}}}
			api:editMessageText(msg.chat.id, msg.message_id, nil,
				i18n("Cryptogasmic groups and channels:\n[Chat Group](https://t.me/cryptogasmic1)\n[Social Group](https://t.me/joinchat/Gp0E6E6aKGVvFMNW7TA_6w)\n[Krypto's Updates](https://t.me/kryptogasmic)\n[Crypto News](https://t.me/Cryptogasmicnews)"),
				"Markdown", nil, markup)
		end
	end
end

_M.triggers = {
	onTextMessage = {
		config.cmd..'(ping)$',
		config.cmd..'(echo) (.*)$',
		config.cmd..'(about)$',
		config.cmd..'(group)s?$',
		'^/start (group)s$'
	},
	onCallbackQuery = {
		'^###cb:fromhelp:(about)$',
		'^###cb:private:(group)s$'
	}
}

return _M
