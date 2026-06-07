

module.exports = {
	data: new SlashCommandBuilder()
		.setName('punishmenthistory')
		.setDescription('View punishment history for a player by Discord ID')
		.addStringOption(option =>
			option.setName('discordid')
				.setDescription('The Discord user ID of the player')
				.setRequired(true))
		.addStringOption(option =>
			option.setName('removeid')
				.setDescription('Action ID to remove (requires easyadmin.player.actionhistory.delete)')
				.setRequired(false)),
	async execute(interaction, exports) {
		// Must have view permission at minimum
		if (!await DoesGuildMemberHavePermission(interaction.member, 'player.actionhistory.view')) {
			return interaction.reply({ content: 'Insufficient permissions: `easyadmin.player.actionhistory.view`', ephemeral: true })
		}

		const discordId = interaction.options.getString('discordid').trim().replace(/[<@!>]/g, '')
		const removeId = interaction.options.getString('removeid')

		// Handle action removal
		if (removeId) {
			if (!await DoesGuildMemberHavePermission(interaction.member, 'player.actionhistory.delete')) {
				return interaction.reply({ content: 'Insufficient permissions: `easyadmin.player.actionhistory.delete`', ephemeral: true })
			}

			const actionId = parseInt(removeId)
			if (isNaN(actionId)) {
				return interaction.reply({ content: '❌ Invalid action ID — must be a number.', ephemeral: true })
			}

			exports[EasyAdmin].deleteActionHistory(actionId)

			LogDiscordMessage(
				`🗑️ **${interaction.user.tag}** removed action history entry **#${actionId}** for Discord ID \`${discordId}\``,
				'moderation',
				0xE74C3C
			)

			let embed = new EmbedBuilder()
				.setColor(0x2ECC71)
				.setTitle('🗑️ Action Removed')
				.setDescription(`Action **#${actionId}** has been removed from the history for <@${discordId}>.`)
				.setTimestamp()
				.setFooter({ text: `Removed by ${interaction.user.tag}` })

			return interaction.reply({ embeds: [embed] })
		}

		// Fetch history
		const history = await exports[EasyAdmin].getActionHistory(discordId)

		if (!history || history.length === 0) {
			let embed = new EmbedBuilder()
				.setColor(0x95A5A6)
				.setTitle('📋 No Punishment History')
				.setDescription(`No punishment history found for <@${discordId}> (\`${discordId}\`).`)
				.setTimestamp()
				.setFooter({ text: 'EasyAdmin Action History' })
			return interaction.reply({ embeds: [embed] })
		}

		// Try to fetch Discord user for display
		let discordUser = null
		try {
			discordUser = await client.users.fetch(discordId)
		} catch(e) {}

		const canDelete = await DoesGuildMemberHavePermission(interaction.member, 'player.actionhistory.delete')

		// Build paginated embeds — max 5 entries per page
		const pageSize = 5
		const pages = []

		for (let i = 0; i < history.length; i += pageSize) {
			const chunk = history.slice(i, i + pageSize)

			let embed = new EmbedBuilder()
				.setColor(0xE67E22)
				.setTitle(`📋 Punishment History${discordUser ? ` — ${discordUser.tag}` : ` — ${discordId}`}`)
				.setTimestamp()
				.setFooter({ text: `EasyAdmin Action History • Page ${Math.floor(i/pageSize)+1}/${Math.ceil(history.length/pageSize)} • ${history.length} total entries` })

			if (discordUser) {
				embed.setThumbnail(discordUser.displayAvatarURL())
			}

			for (const entry of chunk) {
				const actionType = (entry.action || 'UNKNOWN').replace(/~[a-z]~/gi, '').trim()
				const moderator = entry.moderator || 'Unknown'
				const reason = entry.reason || 'No reason provided'
				const entryId = entry.id || '?'
				const banId = entry.banId && entry.banId !== '' ? entry.banId : null
				const expireString = (() => {
				    if (!entry.banId || !entry.expireString) return null
				    if (!entry.expire || entry.expire >= 10444633200) return entry.expireString || null
				    const months = ['January','February','March','April','May','June','July','August','September','October','November','December']
				    const diff = entry.expire - Math.floor(Date.now() / 1000)
				    if (diff <= 0) return 'Expired'
				    const years   = Math.floor(diff / 31536000)
				    const days    = Math.floor((diff % 31536000) / 86400)
				    const hours   = Math.floor((diff % 86400) / 3600)
				    const minutes = Math.floor((diff % 3600) / 60)
				    const parts = []
				    if (years)   parts.push(years   + 'y')
				    if (days)    parts.push(days    + 'd')
				    if (hours)   parts.push(hours   + 'h')
				    if (minutes) parts.push(minutes + 'm')
				    if (!parts.length) parts.push('< 1m')
				    const d = new Date(entry.expire * 1000)
				    return parts.join(' ') + ' (' + d.getDate() + ', ' + months[d.getMonth()] + ', ' + d.getFullYear() + ')'
				})()
	
				const actionLabel = banId ? `${actionType} \`${banId}\`` : actionType
				let fieldValue = `**Moderator:** ${moderator}\n**Reason:** ${reason}`
				if (expireString) {
					fieldValue += `\n**Expires:** ${expireString}`
				}
				if (canDelete) {
					fieldValue += `\n*Remove: \`/punishmenthistory discordid:${discordId} removeid:${entryId}\`*`
				}
	
				embed.addFields([{
					name: `[#${entryId}] ${actionLabel}`,
					value: fieldValue,
					inline: false
				}])
			}

			pages.push(embed)
		}

		if (pages.length === 1) {
			return interaction.reply({ embeds: [pages[0]] })
		}

		// Multi-page with navigation buttons
		let currentPage = 0
		const timestamp = Date.now()

		const prevButton = new ButtonBuilder()
			.setCustomId(`ph_prev_${timestamp}`)
			.setLabel('◀ Previous')
			.setStyle(2)
			.setDisabled(true)

		const nextButton = new ButtonBuilder()
			.setCustomId(`ph_next_${timestamp}`)
			.setLabel('Next ▶')
			.setStyle(2)
			.setDisabled(pages.length <= 1)

		const row = new ActionRowBuilder().addComponents(prevButton, nextButton)

		await interaction.reply({ embeds: [pages[0]], components: [row] })

		const collector = interaction.channel.createMessageComponentCollector({
			filter: i => (i.customId === `ph_prev_${timestamp}` || i.customId === `ph_next_${timestamp}`) && i.user.id === interaction.user.id,
			time: 120000
		})

		collector.on('collect', async i => {
			if (i.customId === `ph_next_${timestamp}`) currentPage++
			else if (i.customId === `ph_prev_${timestamp}`) currentPage--

			currentPage = Math.max(0, Math.min(pages.length - 1, currentPage))

			prevButton.setDisabled(currentPage === 0)
			nextButton.setDisabled(currentPage === pages.length - 1)

			const updatedRow = new ActionRowBuilder().addComponents(prevButton, nextButton)
			await i.update({ embeds: [pages[currentPage]], components: [updatedRow] })
		})

		collector.on('end', async () => {
			prevButton.setDisabled(true)
			nextButton.setDisabled(true)
			const disabledRow = new ActionRowBuilder().addComponents(prevButton, nextButton)
			await interaction.editReply({ components: [disabledRow] }).catch(() => {})
		})
	},
}
