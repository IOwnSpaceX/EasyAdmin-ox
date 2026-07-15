/*eslint no-global-assign: "off", no-unused-vars: "off"*/
process.on('uncaughtException', function(err) {
	console.log('Caught exception: ', err.stack)
})
process.on('unhandledRejection', function(err) {
	if (err.message.includes('this.rest.clearHashSweeper is not a function')) {
		setTimeout(() => {
			console.log('^1EasyAdmin ^3FATAL ERROR! ^7Your Discord Token is Invalid, EasyAdmin\'s Discord Bot ^1will not work ^7until this error has been resolved! Please check your Discord Token and try again.')
		}, 1000)
		return
	} else if (err.message.includes('disallowed intents')) {
		setTimeout(() => {
			console.log('^1EasyAdmin ^3FATAL ERROR! ^7Your Discord Bot does not have the correct intents enabled, EasyAdmin\'s Discord Bot ^1will not work ^7until this error has been resolved! Please refer to the documentation: https://easyadmin.readthedocs.io/en/latest/discordbot/#creating-the-bot-user')
		}, 1000)
		return
	}
	console.log('Caught rejection: ', err.stack)
})

const _djs = require('discord.js')
const _builders = require('@discordjs/builders')
const _rest = require('@discordjs/rest')
const _routes = require('discord-api-types/v9')

Client = _djs.Client
EmbedBuilder = _djs.EmbedBuilder || _djs.MessageEmbed
Collection = _djs.Collection
Partials = _djs.Partials || { GuildMember: 'GUILD_MEMBER', User: 'USER', Message: 'MESSAGE', Channel: 'CHANNEL', Reaction: 'REACTION' }
ButtonStyle = _djs.ButtonStyle
ActionRowBuilder = _djs.ActionRowBuilder || _djs.MessageActionRow
ButtonBuilder = _djs.ButtonBuilder || _djs.MessageButton
StringSelectMenuBuilder = _djs.StringSelectMenuBuilder || _djs.MessageSelectMenu
ModalBuilder = _djs.ModalBuilder || _djs.Modal
TextInputBuilder = _djs.TextInputBuilder
GatewayIntentBits = _djs.GatewayIntentBits || { Guilds: _djs.Intents.FLAGS.GUILDS, GuildMessages: _djs.Intents.FLAGS.GUILD_MESSAGES, GuildMembers: _djs.Intents.FLAGS.GUILD_MEMBERS, MessageContent: _djs.Intents.FLAGS.MESSAGE_CONTENT }
InteractionType = _djs.InteractionType
TextInputStyle = _djs.TextInputStyle
SlashCommandBuilder = _builders.SlashCommandBuilder
REST = _rest.REST
Routes = _routes.Routes

client = new Client({
	partials: [Partials.GuildMember, Partials.User, Partials.Message, Partials.Channel, Partials.Reaction],
	intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages, GatewayIntentBits.GuildMembers, GatewayIntentBits.MessageContent]
})
client.commands = new Collection()

// functions.js
async function prepareGenericEmbed(message,feature,colour,title,image,customAuthor,description,timestamp) {
	if (feature && await exports[EasyAdmin].isWebhookFeatureExcluded(feature)) {
		return
	}
	const embed = new EmbedBuilder()
		.setColor(colour || 0x5865F2)
	if (timestamp != false) {
		embed.setTimestamp()
	}
	if (message) {
		embed.setDescription(message)
	}
	if (title) {
		embed.setTitle(title)
	} else if (message && !description) {
		// no-op: message goes to description now
	}
	if (description) {
		embed.setDescription(description)
	}
	if (customAuthor) {
		embed.setAuthor(customAuthor)
	}
	if (image) {
		embed.setImage(image)
	}
	embed.setFooter({ text: 'EasyAdmin' })
	return embed
}

async function findPlayerFromUserInput(input) {
	var user
	var players = await exports[EasyAdmin].getCachedPlayers()
	Object.keys(players).forEach(function(key) {
		var player = players[key]
		var name = player.name
		if(!isNaN(input)) {
			if (player.id == input) {
				user = player
			}
		} else {
			if (name.search(input) != -1) {
				user = player
			}
		}
	})
	return user
}

async function DoesGuildMemberHavePermission(member, object) {
	if (!member || !object) { return false }
	var memberId = member.id
	if(!memberId) {
		return false
	}
	if (object.search('easyadmin.') == -1) {
		object = `easyadmin.${object}`
	}
	if (member.guild.ownerId === memberId) {
		return true
	}
	var allowed=IsPrincipalAceAllowed(`identifier.discord:${memberId}`, object)
	return allowed
}

async function getDiscordAccountFromPlayer(user) {
	var discordAccount = false
	if (!isNaN(user)) {
		user = await exports[EasyAdmin].getCachedPlayer(user)
	}
	for (let identifier of user.identifiers) {
		if (identifier.search('discord:') != -1) {
			discordAccount = await client.users.fetch(identifier.substring(identifier.indexOf(':') + 1))
		}
	}
	return discordAccount
}

async function getPlayerFromDiscordAccount(user) {
	var id = user.id
	var players = await exports[EasyAdmin].getCachedPlayers()
	for (let [index, player] of Object.values(players).entries()) {
		for (let identifier of player.identifiers) {
			if (identifier == `discord:${id}`) {
				return player
			}
		}
	}
	return false
}

async function refreshRolesForMember(member) {
	var roles = await member.roles.cache.keys()
	for (var role of roles) {
		emit('debug', `role sync for ${member.user.tag} add_principal identifier.discord:${member.id} role:${role}`)
		ExecuteCommand(`add_principal identifier.discord:${member.id} role:${role}`)
	}
	emit('debug', `roles synced for ${member.user.tag}`)
}

async function refreshRolesForUser(user,roles) {
	for (var role of roles) {
		emit('debug', `role sync for ${user.tag} add_principal identifier.discord:${user.id} role:${role}`)
		ExecuteCommand(`add_principal identifier.discord:${user.id} role:${role}`)
	}
	emit('debug', `roles synced for ${user.tag}`)
}

function format(str, ...args) {
	let formatted = str.replace(/%s/g, function() {
		return args.shift()
	})
	return formatted
}

// logging.js
botLogForwards = []
async function addBotLogForwarding(source,args) {
	var player=source
	if (await exports[GetCurrentResourceName()].DoesPlayerHavePermission(player, 'server')) {
		var feature = args[0]
		var channel = args[1]
		if (!feature || !parseInt(channel)) {
			console.error('Invalid Usage! ea_addBotLogForwarding feature channelId')
			return false
		}
		console.log(`Added log fwd ${feature} => ${channel}`)
		botLogForwards[feature] = channel
		return true
	}
}

RegisterCommand('ea_addBotLogForwarding', addBotLogForwarding)

async function LogDiscordMessage(text, feature, colour) {
	if (!EasyAdmin) {return}
	if (GetConvar('ea_botLogChannel', '') == '') {return}
	if (feature == 'report' || feature == 'calladmin') {return}
	const embed = await prepareGenericEmbed(text,undefined,colour)
	var channelId
	if ((feature == 'jail') && GetConvar('ea_jailLogChannel', '') != '') {
		channelId = GetConvar('ea_jailLogChannel', '')
	} else {
		channelId = botLogForwards[feature] || GetConvar('ea_botLogChannel', '')
	}
	var channel = await client.channels.cache.get(channelId)
	if (channel) {
		channel.send({ embeds: [embed] }).catch((error) => {
			console.error('^7Failed to log message, please make sure you gave the bot permission to write in the log channel!\n\n')
			console.error(error)
		})
	} else {
		console.error('^7Failed to log message, please make sure you gave the bot permission to write in the log channel!\n\n')
	}
}
exports('LogDiscordMessage', LogDiscordMessage)

// roles.js
async function syncDiscordRoles(player) {
	if (!EasyAdmin) {return}
	var user
	try {
		var identifiers = await exports[EasyAdmin].getAllPlayerIdentifiers(player)
		for (let identifier of identifiers) {
			if (identifier.search('discord:') != -1) {
				user = await client.users.fetch(identifier.substring(identifier.indexOf(':') + 1))
			}
		}
		if (!user) {
			return false
		}
	} catch (error) {
		return
	}
	var roles = []
	for (const id of client.guilds.cache.keys()) {
		const guild = client.guilds.cache.get(id)
		if (guild.members.cache.has(user.id)) {
			var guildMember = await guild.members.fetch(user.id)
			if (guildMember) {
				roles.push(...guildMember.roles.cache.keys())
			}
		}
	}
	refreshRolesForUser(user, roles)
}
exports('syncDiscordRoles', syncDiscordRoles)

if (GetConvar('ea_botToken', '') != '') {
	client.on('guildMemberUpdate', async function(oldMember, newMember){
		oldRoles = await oldMember.roles.cache.keys()
		newRoles = await newMember.roles.cache.keys()
		for (let role of oldRoles) {
			ExecuteCommand(`remove_principal identifier.discord:${oldMember.id} role:${role}`)
		}
		for (let role of newRoles) {
			ExecuteCommand(`add_principal identifier.discord:${newMember.id} role:${role}`)
		}
	})
}

// reports.js
var reports = []

function generateReportEmbed(report, disabled, closed) {
	var embed = new EmbedBuilder()
		.setTimestamp()
	if (closed) {
		embed.setColor(808080)
	} else {
		embed.setColor(65280)
	}
	if (report.type == 1) {
		embed.addFields([{name:'Player Report', value: `**${report.reporterName}** reported **${report.reportedName}**!`}])
	} else {
		embed.addFields([{name:'Admin Call', value: `**${report.reporterName}** called for an Admin!`}])
	}
	embed.addFields([
		{name:'Reason', value: `\`\`\`\n${report.reason}\`\`\``},
		{name:'Report ID', value: `#${report.id}`, inline: true},
		{name:'Claimed by', value:`${(report.claimedName || 'Noone')}`, inline: true}])
	return {embeds: [embed]}
}

async function logNewReport(report) {
	if (GetConvar('ea_botToken', '') != '') {
		var reportId = report.id
		reports[reportId] = report
		var reportMessage = generateReportEmbed(report)
		var channel = await client.channels.cache.get(GetConvar('ea_botLogChannel', ''))
		if (report.type == 1 && botLogForwards['report']) {
			channel = await client.channels.cache.get(botLogForwards['report'])
		} else if (report.type == 0 && botLogForwards['calladmin']) {
			channel = await client.channels.cache.get(botLogForwards['calladmin'])
		}
		var msg = await channel.send(reportMessage)
		reports[reportId].msg = msg
	} else {
		return false
	}
}

on('EasyAdmin:reportAdded', async function(reportdata) {
	logNewReport(reportdata)
})

on('EasyAdmin:reportClaimed', async function (reportdata) {
	var reportId = reportdata.id
	if(reports[reportId]) {
		reports[reportId].claimed = reportdata.claimed
		reports[reportId].claimedName = reportdata.claimedName
		let reportMessage = generateReportEmbed(reports[reportId], true)
		reports[reportId].msg.edit(reportMessage)
	}
})

on('EasyAdmin:reportRemoved', async function(reportdata) {
	var reportId = reportdata.id
	if(reports[reportId]) {
		var reportMessage = generateReportEmbed(reports[reportId], true, true)
		reports[reportId].msg.edit(reportMessage)
		reports[reportId] = undefined
	}
})

// player_events.js
if (GetConvar('ea_botToken', '') != '') {

	on('playerJoining', function () {
		const player = global.source
		if (GetConvar('ea_botToken', '') != '' && GetConvar('ea_botLogChannel', '') != '') {
			var msg = `Player **${exports[EasyAdmin].getName(player,true,true)}** with id **${player}** joined the Server!`
			LogDiscordMessage(msg, 'joinleave')
		}
	})

	on('playerConnecting', function () {
		if (GetConvar('ea_botToken', '') == '') return
		const player = global.source
		exports[EasyAdmin].syncDiscordRoles(player)
	})

	on('playerDropped', () => {
		if (GetConvar('ea_botToken', '') == '') return
		var player = global.source
		if (GetConvar('ea_botChatBridge', '') != '') {
			knownAvatars[player] = undefined
		}
		if (GetConvar('ea_botLogChannel', '') != '') {
			var msg = `Player **${exports[EasyAdmin].getName(player,true,true)}** left the server!`
			LogDiscordMessage(msg, 'joinleave')
		}
	})

}

// chat_bridge.js
try {
	knownAvatars = {}
	exports['chat'].registerMessageHook(async function(source, outMessage) {
		if (GetConvar('ea_botChatBridge', '') == '') { return }
		const user = await exports[EasyAdmin].getCachedPlayer(source)
		if (!user) {
			return
		}
		var userInfo = {name: outMessage.args[0]}
		if (knownAvatars[source] == undefined) {
			var fivemAccount = false
			for (let identifier of user.identifiers) {
				if (identifier.search('fivem:') != -1) {
					fivemAccount = identifier.substring(identifier.indexOf(':') + 1)
				}
			}
			if (fivemAccount) {
				var response = await exports[EasyAdmin].HTTPRequest(`https://policy-live.fivem.net/api/getUserInfo/${fivemAccount}`)
				try {
					response = JSON.parse(response)
					if (response.avatar_template) {
						var avatarURL = response.avatar_template.replace('{size}', '96')
						if (avatarURL.indexOf('http') == -1) {
							avatarURL = `https://forum.cfx.re${avatarURL}`
						}
						userInfo.iconURL = avatarURL
						knownAvatars[source] = avatarURL
					} else {
						knownAvatars[source] = false
					}
				} catch {
					knownAvatars[source] = false
				}
			} else {
				knownAvatars[source] = false
			}
		} else {
			userInfo.iconURL = knownAvatars[source]
		}
		if (knownAvatars[source] == false) {
			userInfo.iconURL = undefined
		}
		var embed = await prepareGenericEmbed(undefined, undefined, 55555, undefined, undefined, userInfo, outMessage.args[1], false)
		client.channels.cache.get(GetConvar('ea_botChatBridge', '')).send({ embeds: [embed] })
	})
} catch(error) {
	if (GetConvar('ea_botChatBridge', '') != '') {
		console.error('Registering Chat Bridge failed, you will need to update your chat resource from https://github.com/citizenfx/cfx-server-data to use it.')
	}
}

client.on('messageCreate', async msg => {
	if (GetConvar('ea_botChatBridge', '') == '') { return }
	if (!msg.member || msg.author.bot) { return }
	if(msg.author.id == userID) {
		return
	}
	if(!msg.channel) { return }
	if (msg.channel.id == GetConvar('ea_botChatBridge', '')) {
		exports['chat'].addMessage(-1, { args: [msg.member.user.tag, msg.cleanContent]})
	}
})

on('playerDropped', () => {
	if (GetConvar('ea_botChatBridge', '') == '') { return }
	knownAvatars[global.source] = undefined
})

// server_status.js
var statusMessage
var startTimestamp = new Date()

async function getServerStatus(why) {
	var embed = new EmbedBuilder()
		.setColor(65280)
		.setTimestamp()
	var joinURL = GetConvar('web_baseUrl', '')
	var buttonRow = false
	if(joinURL != '' && joinURL.indexOf('cfx.re' != -1) && joinURL.match(/^[^A-z0-9]/)==null) {
		embed.setURL(`https://${joinURL}`)
		buttonRow = new ActionRowBuilder()
		var button = new ButtonBuilder()
			.setURL(`https://${joinURL}`)
			.setLabel('Join Server')
			.setStyle(ButtonStyle && ButtonStyle.Link    || 5)
		buttonRow.addComponents([button])
	} else {
		joinURL = ''
	}
	var serverName = GetConvar('sv_projectName', GetConvar('sv_hostname', 'default FXServer'))
	if (serverName.length > 255) {
		serverName = serverName.substring(0,255)
	}
	serverName = serverName.replace(/\^[0-9]/g, '')
	embed.addFields([{name: 'Server Name', value: `\`\`\`${serverName}\`\`\``}])
	var activeReports = 0
	var claimedReports = 0
	var allReports = await exports[EasyAdmin].getAllReports()
	for (let report of Object.values(allReports).entries()) {
		activeReports+=1
		if (report.claimed) {
			claimedReports+=1
		}
	}
	embed.addFields([
		{ name: 'Players Online', value: `\`\`\`${getPlayers().length}/${GetConvar('sv_maxClients', '')}\`\`\``, inline: true},
		{ name: 'Admins Online', value: `\`\`\`${Object.values(exports[EasyAdmin].GetOnlineAdmins()).length}\`\`\``, inline: true},
		{ name: 'Reports', value: `\`\`\`${activeReports} (${claimedReports} claimed)\`\`\``, inline: true},
		{ name: 'Active Vehicles', value: `\`\`\`${GetAllVehicles().length}\`\`\``, inline: true},
		{ name: 'Active Peds', value: `\`\`\`${GetAllPeds().length}\`\`\``, inline: true},
		{ name: 'Active Objects', value: `\`\`\`${GetAllObjects().length}\`\`\``, inline: true}
	])
	if (joinURL != '') {
		try {
			let serverId = joinURL.substring(joinURL.lastIndexOf('-')+1,joinURL.indexOf('.users.cfx.re'))
			let response = await exports[EasyAdmin].HTTPRequest(`https://servers-frontend.fivem.net/api/servers/single/${serverId}`)
			response = JSON.parse(response).Data
			embed.addFields([{ name: 'Upvotes', value: `\`\`\`${response.upvotePower} Upvotes, ${response.burstPower} Bursts\`\`\``, inline: false}])
			embed.setAuthor({ name: `${serverName}`, iconURL: response.ownerAvatar, url: `https://${joinURL}`})
		} catch (error) {
			console.error(error)
		}
	}
	embed.addFields([{ name: 'Uptime', value: `\`\`\`${(function(ms){const s=Math.floor(ms/1000),m=Math.floor(s/60),h=Math.floor(m/60),d=Math.floor(h/24);const parts=[];if(d)parts.push(`${d} day${d!==1?'s':''}`);if(h%24)parts.push(`${h%24} hour${h%24!==1?'s':''}`);if(m%60)parts.push(`${m%60} minute${m%60!==1?'s':''}`);if(s%60)parts.push(`${s%60} second${s%60!==1?'s':''}`);return parts.join(', ')||'0 seconds'})(new Date()-startTimestamp)}\`\`\``, inline: false}])
	if (why) {
		embed.addFields([{name: 'Last Update', value: why}])
	}
	if (buttonRow) {
		return {embeds: [embed], components: [buttonRow] }
	}
	return {embeds: [embed] }
}

async function updateServerStatus(why) {
	if (GetConvar('ea_botStatusChannel', '') == '') { return }
	var channel = await client.channels.fetch(GetConvar('ea_botStatusChannel', ''))
	if (channel == undefined) {
		console.error('Failed to configure bot status channel, please make sure the channel id is correct and the bot has read and write access.')
		return
	}
	if (!statusMessage) {
		var messagesToDelete = []
		var messages = await channel.messages.fetch({ limit: 10 }).catch((error) => {
			console.error('^7Failed to configure server status channel, please make sure you gave the bot permission to write in the channel!\n\n')
			console.error(error)
		})
		for (var message of messages.values()) {
			if (messages.size == 1 && message.author.id == client.user.id) {
				statusMessage = message
				break
			} else {
				messagesToDelete.push(message.id)
			}
		}
		try {
			if (statusMessage) {
				updateServerStatus()
				return
			}
			await channel.bulkDelete(messagesToDelete)
		} catch (error) {
			console.log('Could not bulk-delete messages in botStatusChannel.')
			console.error(error)
		}
		let embed = await prepareGenericEmbed('Fetching Server Infos..')
		statusMessage = await channel.send({ embeds: [embed] })
	}
	const embed = await getServerStatus(why)
	statusMessage.edit(embed)
}

client.on('messageCreate', async msg => {
	if (!msg.member || msg.author.bot) { return }
	if(msg.author.id == userID) {
		return
	}
	if(!msg.channel) { return }
	if (msg.channel.id == GetConvar('ea_botStatusChannel', '')) {
		msg.delete()
		updateServerStatus('manual')
	}
})
setTimeout(updateServerStatus, 10000)
setInterval(updateServerStatus, 180000)

// main bot logic
var _slashCommandListenerRegistered = false
async function RegisterClientCommands(clientId) {
	const fs = require('fs')
	const commands = []
	const commandFiles = fs.readdirSync(`${resourcePath}/server/bot/commands`).filter(file => file.endsWith('.js'))
	for (const file of commandFiles) {
		const command = require(`${resourcePath}/server/bot/commands/${file}`)
		commands.push(command.data.toJSON())
		client.commands.set(command.data.name, command)
	}
	const rest = new REST({ version: '9' }).setToken(GetConvar('ea_botToken', ''))
	if (guild != '') {
		rest.put(Routes.applicationGuildCommands(clientId, guild), { body: {} })
	}
	await rest.put(
		Routes.applicationCommands(clientId),
		{ body: commands },
	)
	if (_slashCommandListenerRegistered) { return }
	_slashCommandListenerRegistered = true
	client.on('interactionCreate', async interaction => {
		if (!interaction.isCommand()) return
		const command = client.commands.get(interaction.commandName)
		if (!command) return
		if (!(await DoesGuildMemberHavePermission(interaction.member, `bot.${command.data.name}`) == true) && !(command.data.name == 'refreshperms')) {
			await refreshRolesForMember(interaction.member)
			if (!(await DoesGuildMemberHavePermission(interaction.member, `bot.${command.data.name}`) == true)) {
				await interaction.reply({ content: 'You don\'t have permission to run this command!', ephemeral: true })
				return false
			}
		}
		try {
			await command.execute(interaction, exports)
		} catch (error) {
			console.error(error)
			var errorContent = { content: `There was an error while executing this command, please report the following stack trace here: <https://github.com/Blumlaut/EasyAdmin/issues> \`\`\`js\n${error.stack}\`\`\``, ephemeral: true }
			if (interaction.replied) {
				interaction.followUp(errorContent)
			} else {
				interaction.reply(errorContent)
			}
		}
	})
}

if (GetConvar('ea_botToken', '') != '') {

var _botReadyOneTimeSetupDone = false
client.on('ready', async () => {
	console.log(`Logged in as ${client.user.tag}!`)
	client.user.setPresence({ activities: [{ name: `${GetConvar('sv_projectName', GetConvar('sv_hostname', 'default FXServer'))}`, type: 'WATCHING' }], status: 'online' })
	userID = client.user.id
	resourcePath = GetResourcePath(GetCurrentResourceName())
	guild = GetConvar('ea_botGuild', '')
	EasyAdmin = GetCurrentResourceName()

	if (_botReadyOneTimeSetupDone) { return }
	_botReadyOneTimeSetupDone = true

	currentVersion = await exports[EasyAdmin].GetVersion()[0]
	latestVersionInfo = await exports[EasyAdmin].getLatestVersion()
	RegisterClientCommands(client.user.id)
	var startupMessage = `**EasyAdmin ${currentVersion}** has started.`
	if (currentVersion != latestVersionInfo[0]) {
		startupMessage+=`\nVersion ${latestVersionInfo[0]} is Available!\n Download it from ${latestVersionInfo[1]}`
	}
	LogDiscordMessage(startupMessage, 'startup')

		//Ban Management Log System
		const _banMgmtSent = new Set()

		async function resolveDiscordMemberByTag(tag) {
			for (const guild of client.guilds.cache.values()) {
				try {
					const members = await guild.members.fetch({ query: tag.replace(/\[.*?\]/g, '').trim(), limit: 1 })
					if (members.size) return members.first()
				} catch (_) {}
			}
			return null
		}
		function buildBanEmbed(banData, state, actionUser) {
			const colours = { pending: 0xF1C40F, approved: 0x2ECC71, revoked: 0xE74C3C }
			const titles  = { pending: '🔨 Ban Issued', approved: '✅ Ban Approved', revoked: '❌ Ban Revoked' }

			const isPermanent = !banData.expire || banData.expire >= 10444633200

			const embed = new EmbedBuilder()
				.setColor(colours[state] || colours.pending)
				.setTitle(titles[state] || titles.pending)
				.setDescription('A player has been banned from the server')
				.addFields(
					{
						name: '👤 Banned Player',
						value: banData.discordMention ? `${banData.discordMention}\n${banData.name}` : `\`${banData.name || 'Unknown'}\``,
						inline: true,
					},
					{
						name: '🛡️ Banned By',
						value: banData.bannerMention ? `${banData.bannerMention} ${banData.banner}` : `\`${banData.banner || 'Unknown'}\``,
						inline: true,
					},
					{
						name: '🆔 Ban ID',
						value: `\`#${banData.banid}\``,
						inline: true,
					},
					{
						name: '📋 Reason',
						value: `\`\`\`\n${banData.reason || 'No reason provided'}\n\`\`\``,
						inline: false,
					},
					{
						name: '⏱️ Duration',
						value: banData.durationLabel || (isPermanent ? 'Permanent' : 'Temporary'),
						inline: true,
					},
					{
						name: '🗓️ Expires',
						value: isPermanent
							? '`Never`'
							: `<t:${Math.floor(banData.expire)}:F> | <t:${Math.floor(banData.expire)}:R>`,
						inline: true,
					},
				)
				.setTimestamp()

			let footerText = `EasyAdmin • Ban ID: #${banData.banid}`
			if (actionUser && state === 'approved') footerText += ` • Approved by ${actionUser.tag} (${actionUser.id})`
			if (actionUser && state === 'revoked')  footerText += ` • Revoked by ${actionUser.tag} (${actionUser.id})`
			embed.setFooter({ text: footerText })

			return embed
		}
		function buildBanButtons(banId, disabled) {
			return new ActionRowBuilder().addComponents(
				new ButtonBuilder()
					.setCustomId(`banmgmt_approve_${banId}`)
					.setLabel('Approved')
					.setStyle(ButtonStyle && ButtonStyle.Success || 3)
					.setDisabled(!!disabled),
				new ButtonBuilder()
					.setCustomId(`banmgmt_revoke_${banId}`)
					.setLabel('Revoke')
					.setStyle(ButtonStyle && ButtonStyle.Danger || 4)
					.setDisabled(!!disabled),
				new ButtonBuilder()
					.setCustomId(`banmgmt_proof_${banId}`)
					.setLabel('Remind for Ban Proof')
					.setStyle(ButtonStyle && ButtonStyle.Primary || 1)
					.setDisabled(!!disabled),
			)
		}

		function buildSingleButton(customId, label, style) {
			return new ActionRowBuilder().addComponents(
				new ButtonBuilder()
					.setCustomId(customId)
					.setLabel(label)
					.setStyle(style)
					.setDisabled(true),
			)
		}

		async function sendBanLog(banData) {
			const channelId = GetConvar('ea_banLogChannel', '')
			if (!channelId || channelId === '' || channelId === 'false' || channelId === 'none') return
			if (_banMgmtSent.has(banData.banid)) return
			_banMgmtSent.add(banData.banid)
			setTimeout(() => _banMgmtSent.delete(banData.banid), 5000)

			const channel = await client.channels.fetch(channelId).catch(() => null)
			if (!channel) {
				console.error('[EasyAdmin BanMgmt] Could not find ea_banLogChannel — check the channel ID and bot permissions.')
				return
			}
			if (banData.identifiers) {
				for (const id of banData.identifiers) {
					if (id && id.startsWith('discord:')) {
						banData.discordMention = `<@${id.slice(8)}>`
						break
					}
				}
			}
			if (banData.bannerDiscord) {
				banData.bannerMention = `<@${banData.bannerDiscord}>`
			}

			const embed   = buildBanEmbed(banData, 'pending')
			const buttons = buildBanButtons(banData.banid, false)

			let message
			try {
				message = await channel.send({ embeds: [embed], components: [buttons] })
			} catch (err) {
				console.error('[EasyAdmin BanMgmt] Failed to send ban log message:', err)
				return
			}
			try {
				const safePlayerName = (banData.name || 'Unknown').replace(/[^\w\s-]/g, '').trim().substring(0, 50)
				const thread = await message.startThread({
					name: `Ban #${banData.banid} - ${safePlayerName}`,
					autoArchiveDuration: 10080,
				})

				let pingText = '@here'
				if (banData.bannerDiscord) {
					pingText = `<@${banData.bannerDiscord}>`
				} else if (banData.banner) {
					const found = await resolveDiscordMemberByTag(banData.banner).catch(() => null)
					if (found) pingText = `<@${found.user.id}>`
				}

				await thread.send(
					`${pingText}, please provide proof for this ban.\n` +
					`**Ban ID:** \`#${banData.banid}\` | **Player:** \`${banData.name}\``
				)
			} catch (threadErr) {
				console.error('[EasyAdmin BanMgmt] Could not create proof thread:', threadErr)
			}
		}

		exports('sendBanLog', sendBanLog)

		async function handleBanManagementButton(interaction) {
			if (!interaction.isButton()) return
			const { customId } = interaction
			if (!customId.startsWith('banmgmt_')) return

			await refreshRolesForMember(interaction.member)
			const hasPerm = await DoesGuildMemberHavePermission(interaction.member, 'bot.banmanagement')
			if (!hasPerm) {
				await interaction.reply({ content: 'You do not have permission to manage bans. Required ace: `easyadmin.bot.banmanagement`', ephemeral: true })
				return
			}

			const parts  = customId.split('_')
			const action = parts[1]
			const banId  = parts.slice(2).join('_')
			const actor  = { tag: interaction.user.tag, id: interaction.user.id }

			//APPROVE
			if (action === 'approve') {
				const ban = await exports[EasyAdmin].fetchBan(banId)
				const banData = ban || { banid: banId, name: 'Unknown', banner: 'Unknown', reason: 'N/A', expire: 10444633200 }

				if (ban) {
					const fields = interaction.message.embeds[0] && interaction.message.embeds[0].fields
					if (fields) {
						const playerField = fields.find(f => f.name.includes('Banned Player'))
						const bannerField = fields.find(f => f.name.includes('Banned By'))
						if (playerField) banData.discordMention = playerField.value.split('\n')[0]
						if (bannerField) banData.bannerMention  = bannerField.value.split(' ')[0]
					}
				}

				const updatedEmbed  = buildBanEmbed(banData, 'approved', actor)
				const singleButton  = buildSingleButton(`banmgmt_approve_${banId}`, `Approved by: ${actor.tag} (${actor.id})`, ButtonStyle && ButtonStyle.Success || 3)

				try {
					await interaction.update({ embeds: [updatedEmbed], components: [singleButton] })
				} catch (err) {
					console.error('[EasyAdmin BanMgmt] Approve update failed:', err)
					try { await interaction.reply({ content: '✅ Ban approved.', ephemeral: true }) } catch(_) {}
				}

				try {
					const thread = interaction.message.thread || await interaction.message.fetchThread().catch(() => null)
					if (thread) await thread.send(`✅ Ban **#${banId}** has been **approved** by <@${actor.id}>.`)
				} catch (_) {}
				return
			}

			//REVOKE
			if (action === 'revoke') {
				const ban = await exports[EasyAdmin].fetchBan(banId)
				const ret = await exports[EasyAdmin].unbanPlayer(banId)
				const banData = ban || { banid: banId, name: 'Unknown', banner: 'Unknown', reason: 'N/A', expire: 10444633200 }

				if (ban) {
					const fields = interaction.message.embeds[0] && interaction.message.embeds[0].fields
					if (fields) {
						const playerField = fields.find(f => f.name.includes('Banned Player'))
						const bannerField = fields.find(f => f.name.includes('Banned By'))
						if (playerField) banData.discordMention = playerField.value.split('\n')[0]
						if (bannerField) banData.bannerMention  = bannerField.value.split(' ')[0]
					}
				}

				if (ret) {
					const updatedEmbed = buildBanEmbed(banData, 'revoked', actor)
					const singleButton = buildSingleButton(`banmgmt_revoke_${banId}`, `Revoked by: ${actor.tag} (${actor.id})`, ButtonStyle && ButtonStyle.Danger || 4)

					try {
						await interaction.update({ embeds: [updatedEmbed], components: [singleButton] })
					} catch (err) {
						console.error('[EasyAdmin BanMgmt] Revoke update failed:', err)
						try { await interaction.reply({ content: `❌ Ban \`#${banId}\` revoked.`, ephemeral: true }) } catch(_) {}
					}

					try {
						const thread = interaction.message.thread || await interaction.message.fetchThread().catch(() => null)
						if (thread) await thread.send(`❌ Ban **#${banId}** has been **revoked** by <@${actor.id}>.`)
					} catch (_) {}
				} else {
					await interaction.reply({ content: `Could not revoke ban \`#${banId}\`. It may have already been removed.`, ephemeral: true })
				}
				return
			}

			//REMIND FOR PROOF
			if (action === 'proof') {
				const ban = await exports[EasyAdmin].fetchBan(banId)

				let threadUrl = null
				let thread = null
				try {
					thread = interaction.message.thread || await interaction.message.fetchThread().catch(() => null)
					if (thread) threadUrl = `https://discord.com/channels/${interaction.guildId}/${thread.id}`
				} catch (_) {}

				let staffUser = null
				if (ban && ban.bannerDiscord) {
					try { staffUser = await client.users.fetch(ban.bannerDiscord) } catch (_) {}
				}
				if (!staffUser && ban && ban.banner) {
					const member = await resolveDiscordMemberByTag(ban.banner).catch(() => null)
					if (member) staffUser = member.user
				}

				let dmSent = false
				if (staffUser) {
					try {
						const dmEmbed = new EmbedBuilder()
							.setColor(0xF1C40F)
							.setTitle('📋 Ban Proof Required')
							.setDescription(`You have been reminded to provide proof for a ban you issued.`)
							.addFields(
								{ name: '🆔 Ban ID',    value: `\`#${banId}\``,                         inline: true },
								{ name: '👤 Player',    value: `\`${ban ? ban.name : 'Unknown'}\``,      inline: true },
								{ name: '📋 Reason',    value: ban ? ban.reason : 'N/A',                 inline: false },
								{ name: '🔗 Ban Thread', value: threadUrl ? `[Click here to open](${threadUrl})` : 'Thread not found', inline: false },
							)
							.setTimestamp()
							.setFooter({ text: `Reminder sent by ${actor.tag}` })

						await staffUser.send({ embeds: [dmEmbed] })
						dmSent = true
					} catch (_) {}
				}

				if (thread) {
					try {
						let pingText = ban && ban.bannerDiscord ? `<@${ban.bannerDiscord}>` : (ban ? `\`${ban.banner}\`` : 'the banning staff member')
						await thread.send(`📋 ${pingText}, please provide proof for this ban.\n*(Reminder sent by <@${actor.id}>)*`)
					} catch (_) {}
				}

				const status = dmSent ? '✅ DM sent to the staff member.' : '⚠️ Could not DM the staff member (DMs may be closed or user not found).'
				await interaction.reply({ content: `${status}${thread ? ' A reminder was also posted in the ban thread.' : ''}`, ephemeral: true })
				return
			}
		}

		client.on('interactionCreate', handleBanManagementButton)
		console.log('[EasyAdmin BanMgmt] Ban management button handler registered.')
	})

	client.on('debug', function(info){
		if (GetConvarInt('ea_logLevel', 1) >= 4 ) {
			console.log(`${info}`)
		}
	})
	on('debug', function(info){
		if (GetConvarInt('ea_logLevel', 1) >= 4 ) {
			console.log(`${info}`)
		}
	})

	client.login(GetConvar('ea_botToken', ''))
}
