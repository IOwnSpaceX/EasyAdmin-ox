

function parseDuration(str) {
	const units = { second: 1, minute: 60, hour: 3600, day: 86400, week: 604800 }
	const aliases = { s: 'second', sec: 'second', seconds: 'second', m: 'minute', min: 'minute', mins: 'minute', minutes: 'minute', h: 'hour', hr: 'hour', hrs: 'hour', hours: 'hour', d: 'day', days: 'day', w: 'week', weeks: 'week' }
	if (str.toLowerCase() === 'permanent') return 0
	const regex = /(\d+(?:\.\d+)?)\s*([a-z]+)/gi
	let total = 0, matched = false, match
	while ((match = regex.exec(str)) !== null) {
		const val = parseFloat(match[1])
		const unit = aliases[match[2].toLowerCase()]
		if (!unit) throw new Error(`Unknown unit: ${match[2]}`)
		total += val * units[unit]
		matched = true
	}
	if (!matched) throw new Error('No duration found')
	return Math.floor(total)
}

module.exports = {
	data: new SlashCommandBuilder()
		.setName('staffsuspend')
		.setDescription('Suspend a staff member from clocking in')
		.addStringOption(option =>
			option.setName('discord')
				.setDescription('Discord ID or @mention of the staff member')
				.setRequired(true))
		.addStringOption(option =>
			option.setName('duration')
				.setDescription('Duration (e.g. 1 hour, 7 days, permanent)')
				.setRequired(true))
		.addStringOption(option =>
			option.setName('reason')
				.setDescription('Reason for the suspension')
				.setRequired(true)),
	async execute(interaction, exports) {
		if (!await DoesGuildMemberHavePermission(interaction.member, 'clockin.suspend')) {
			return interaction.reply({ content: 'Insufficient permissions: `clockin.suspend`', ephemeral: true })
		}

		const discordInput = interaction.options.getString('discord')
		const durationStr  = interaction.options.getString('duration')
		const reason       = interaction.options.getString('reason')
		const discordId    = discordInput.replace(/[<@!>]/g, '')

		let duration
		try {
			duration = parseDuration(durationStr)
		} catch (e) {
			return interaction.reply({ content: `Invalid duration: \`${durationStr}\`\nTry: \`1 hour\`, \`7 days\`, \`permanent\``, ephemeral: true })
		}

		const moderator = interaction.user.tag
		exports[EasyAdmin].suspendPlayer(discordId, duration, reason, moderator)

		const untilStr = duration > 0
			? new Date(Date.now() + duration * 1000).toLocaleString('en-GB', { timeZone: 'UTC' }) + ' UTC'
			: 'Permanent'

		const embed = new EmbedBuilder()
			.setColor(0xFF0000)
			.setTitle('🚫 Staff Suspended from Duty')
			.addFields(
				{ name: '🎮 Discord',    value: `<@${discordId}>`,      inline: true },
				{ name: '👮 Moderator',  value: `\`${moderator}\``,     inline: true },
				{ name: '📋 Reason',     value: reason,                  inline: false },
				{ name: '⏰ Expires',    value: untilStr,                inline: false }
			)
			.setFooter({ text: 'EasyAdmin Duty System' })
			.setTimestamp()

		return interaction.reply({ embeds: [embed] })
	}
}
