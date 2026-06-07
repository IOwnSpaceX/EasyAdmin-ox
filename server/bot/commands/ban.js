
function parseDuration(str) {
	const units = { second: 1, minute: 60, hour: 3600, day: 86400, week: 604800, month: 2592000, year: 31536000 }
	const aliases = { s: 'second', sec: 'second', seconds: 'second', m: 'minute', min: 'minute', mins: 'minute', minutes: 'minute', h: 'hour', hr: 'hour', hrs: 'hour', hours: 'hour', d: 'day', days: 'day', w: 'week', weeks: 'week', mo: 'month', months: 'month', y: 'year', years: 'year' }
	const regex = /(\d+(?:\.\d+)?)\s*([a-z]+)/gi
	let total = 0
	let matched = false
	let match
	while ((match = regex.exec(str)) !== null) {
		const val = parseFloat(match[1])
		const unit = aliases[match[2].toLowerCase()]
		if (!unit) throw new Error(`Unknown unit: ${match[2]}`)
		total += val * units[unit]
		matched = true
	}
	if (!matched) throw new Error('No duration found')
	return total
}

module.exports = {
	data: new SlashCommandBuilder()
		.setName('ban')
		.setDescription('Bans a player from the server')
		.addStringOption(option =>
			option.setName('user')
				.setDescription('Username or Server ID')
				.setRequired(true))
		.addStringOption(option =>
			option.setName('reason')
				.setDescription('Reason for the ban')
				.setRequired(true))
		.addStringOption(option =>
			option.setName('timeframe')
				.setDescription('Duration (e.g. 30 mins, 1 hour, 2 weeks, permanent)')
				.setRequired(true)),
	async execute(interaction, exports) {
		const userOrId = interaction.options.getString('user')
		const reason = exports[EasyAdmin].formatShortcuts(interaction.options.getString('reason'))
		const timeframe = exports[EasyAdmin].formatShortcuts(interaction.options.getString('timeframe'))

		const user = await findPlayerFromUserInput(userOrId)

		if (!user || user.dropped) {
			let embed = new EmbedBuilder()
				.setColor(0xE74C3C)
				.setTitle('❌ Player Not Found')
				.setDescription(`No player found matching \`${userOrId}\`.`)
				.setTimestamp()
			return interaction.reply({ embeds: [embed], ephemeral: true })
		}

		var banTime

		try {
			if (timeframe.toLowerCase() == 'permanent') {
				banTime = 10444633200
			} else {
				banTime = await parseDuration(timeframe)
				if (banTime > 10444633200) {
					banTime = 10444633200
				}
			}
		} catch (error) {
			let embed = new EmbedBuilder()
				.setColor(0xE74C3C)
				.setTitle('❌ Invalid Duration')
				.setDescription(`Could not understand: \`${timeframe}\`\nTry: \`30 mins\`, \`1 hour\`, \`7 days\`, \`permanent\``)
				.setTimestamp()
			return interaction.reply({ embeds: [embed], ephemeral: true })
		}

		if (banTime < 10444633200 && !await DoesGuildMemberHavePermission(interaction.member, 'player.ban.temporary')) {
			return interaction.reply({ content: 'Insufficient permissions: `easyadmin.player.ban.temporary`', ephemeral: true })
		} else if (banTime >= 10444633200 && !await DoesGuildMemberHavePermission(interaction.member, 'player.ban.permanent')) {
			return interaction.reply({ content: 'Insufficient permissions: `easyadmin.player.ban.permanent`', ephemeral: true })
		}

		var ban = exports[EasyAdmin].addBan(user.id, reason, banTime, interaction.user.tag)
		if (ban) {
			ban = exports[EasyAdmin].getLastBan()
			const isPermanent = banTime >= 10444633200
			const expireDisplay = isPermanent ? 'Permanent Ban' : (ban && ban.expireString ? ban.expireString : 'Unknown')
			let embed = new EmbedBuilder()
				.setColor(0xE74C3C)
				.setTitle('🔨 Player Banned')
				.addFields([
					{ name: '👤 Player', value: `\`${user.name}\``, inline: true },
					{ name: '🛡️ Banned By', value: `${interaction.user}`, inline: true },
					{ name: '📋 Reason', value: `> ${reason}`, inline: false },
					{ name: '⏳ Duration', value: isPermanent ? '`Permanent`' : `\`${timeframe}\``, inline: true },
					{ name: '🗓️ Expires', value: `\`${ban.expireString}\``, inline: true },
					{ name: '🆔 Ban ID', value: ban && ban.banid ? `\`#${ban.banid}\`` : '`N/A`', inline: true },
				])
				.setTimestamp()
				.setFooter({ text: `Issued via Discord • ${interaction.user.tag}` })

			await interaction.reply({ embeds: [embed] })
		} else {
			let embed = new EmbedBuilder()
				.setColor(0xE74C3C)
				.setTitle('❌ Ban Failed')
				.setDescription(`Failed to ban **${user.name}**. They may be immune.`)
				.setTimestamp()
			await interaction.reply({ embeds: [embed] })
		}
	},
}
