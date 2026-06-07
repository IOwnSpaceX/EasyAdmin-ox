

function formatDuration(seconds) {
	if (!seconds || seconds <= 0) return '0h 0m'
	const h = Math.floor(seconds / 3600)
	const m = Math.floor((seconds % 3600) / 60)
	const s = Math.floor(seconds % 60)
	if (h > 0) return `${h}h ${m}m`
	if (m > 0) return `${m}m ${s}s`
	return `${s}s`
}

function progressBar(percent, length = 20) {
	const filled = Math.round((percent / 100) * length)
	const empty  = length - filled
	return '█'.repeat(filled) + '░'.repeat(empty)
}

module.exports = {
	data: new SlashCommandBuilder()
		.setName('evaluate')
		.setDescription('View duty hour evaluation for a staff member')
		.addStringOption(option =>
			option.setName('discord')
				.setDescription('Discord ID or @mention (leave blank for yourself)')
				.setRequired(false)),
	async execute(interaction, exports) {
		if (!await DoesGuildMemberHavePermission(interaction.member, 'bot.evaluate')) {
			return interaction.reply({ content: 'Insufficient permissions: `bot.evaluate`', ephemeral: true })
		}

		const discordInput = interaction.options.getString('discord')
		const discordId    = discordInput ? discordInput.replace(/[<@!>]/g, '') : interaction.user.id

		const cycleConfig  = exports[EasyAdmin].getClockConfig()
		const cycleNumber  = exports[EasyAdmin].getCycleNumber()
		const totalSeconds = exports[EasyAdmin].getHours(discordId)
		const ranks        = cycleConfig.ranks || []
		const cycleLabel   = cycleConfig.cycle?.label || '2-week cycle'
		const cycleLen     = cycleConfig.cycle?.lengthDays || 14

		const startDate  = new Date(cycleConfig.cycle?.startDate || '2026-01-01')
		const cycleMs    = cycleLen * 86400 * 1000
		const elapsed    = Date.now() - startDate.getTime()
		const cyclesGone = Math.floor(elapsed / cycleMs)
		const cycleStart = new Date(startDate.getTime() + cyclesGone * cycleMs)
		const cycleEnd   = new Date(cycleStart.getTime() + cycleMs)

		const cycleStartStr = cycleStart.toLocaleDateString('en-GB', { month: 'short', day: 'numeric', year: 'numeric' })
		const cycleEndStr   = cycleEnd.toLocaleDateString('en-GB',   { month: 'short', day: 'numeric', year: 'numeric' })

		let rankLabel = 'Staff'
		let required  = cycleConfig.hourRequirement || 14400
		let rankRoleId = null

		try {
			const member = await interaction.guild.members.fetch(discordId).catch(() => null)
			if (member) {
				for (const rank of ranks) {
					if (member.roles.cache.has(rank.roleId)) {
						rankLabel  = rank.label
						required   = rank.required
						rankRoleId = rank.roleId
						break
					}
				}
			}
		} catch (e) {}

		const percent     = Math.min(100, Math.round((totalSeconds / required) * 100))
		const bar         = progressBar(percent)
		const hoursStr    = formatDuration(totalSeconds)
		const requiredStr = formatDuration(required)
		const remaining   = Math.max(0, required - totalSeconds)
		const remainStr   = formatDuration(remaining)
		const statusEmoji = percent >= 100 ? '✅' : percent >= 50 ? '🟡' : '🔴'

		const embed = new EmbedBuilder()
			.setColor(percent >= 100 ? 0x2ECC71 : percent >= 50 ? 0xF39C12 : 0xE74C3C)
			.setTitle('🎯 Staff Hour Evaluation')
			.setDescription(`**Rank:** ${rankRoleId ? `<@&${rankRoleId}>` : rankLabel} • **Required:** ${requiredStr}/${cycleLabel}`)
			.addFields(
				{ name: `📅 Cycle ${cycleNumber} (${cycleStartStr} – ${cycleEndStr})`, value: '\u200B', inline: false },
				{ name: `${statusEmoji} Hours This Cycle`, value: `\`${hoursStr}\` / \`${requiredStr}\`\n${bar} **${percent}%**`, inline: false },
				{ name: '⏳ Remaining', value: percent >= 100 ? '✅ Requirement met!' : `Need **${remainStr}** more`, inline: false }
			)
			.setFooter({ text: `EasyAdmin Duty System • ${cycleLabel} • Cycle ${cycleNumber}` })
			.setTimestamp()

		return interaction.reply({ embeds: [embed], ephemeral: !discordInput })
	}
}
