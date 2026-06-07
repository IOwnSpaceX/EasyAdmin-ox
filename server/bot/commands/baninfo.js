

module.exports = {
	data: new SlashCommandBuilder()
		.setName('baninfo')
		.setDescription('Shows details of a ban')
		.addStringOption(option =>
			option.setName('banid')
				.setDescription('Ban ID')
				.setRequired(true)),
	async execute(interaction, exports) {
		if (!await DoesGuildMemberHavePermission(interaction.member, 'player.ban.view')) {
			return interaction.reply({ content: 'Insufficient permissions: `easyadmin.player.ban.view`', ephemeral: true })
		}

		const banIdRaw = interaction.options.getString('banid').trim()
		const banId = isNaN(banIdRaw) ? banIdRaw : parseInt(banIdRaw)

		var ban = await exports[EasyAdmin].fetchBan(banId)
		if (ban) {
			var discordAccount = false
			for (let identifier of ban.identifiers) {
				if (identifier.search('discord:') != -1) {
					try {
						discordAccount = await client.users.fetch(identifier.substring(identifier.indexOf(':') + 1))
					} catch(e) {}
				}
			}

			const expireDisplay = (() => {
			    if (!ban.expire || ban.expire >= 10444633200) return 'Permanent Ban'
			    const months = ['January','February','March','April','May','June','July','August','September','October','November','December']
			    const diff = ban.expire - Math.floor(Date.now() / 1000)
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
			    const d = new Date(ban.expire * 1000)
			    return parts.join(' ') + ' (' + d.getDate() + ', ' + months[d.getMonth()] + ', ' + d.getFullYear() + ')'
			})()
			const bannedAt = ban.time ? `<t:${ban.time}:F>` : 'Unknown'

			let embed = new EmbedBuilder()
				.setColor(0xE74C3C)
				.setTitle(`🔨 Ban Record — #${banId}`)
				.setTimestamp()
				.setFooter({ text: 'EasyAdmin Ban System' })

			if (discordAccount) {
				embed.setAuthor({ name: discordAccount.tag, iconURL: discordAccount.displayAvatarURL() })
				embed.setThumbnail(discordAccount.displayAvatarURL())
			}

			embed.addFields([
				{ name: '👤 Player', value: `\`${ban.name || 'Unknown'}\``, inline: true },
				{ name: '🛡️ Banned By', value: `\`${ban.banner || 'Unknown'}\``, inline: true },
				{ name: '🕐 Banned At', value: bannedAt, inline: true },
				{ name: '📋 Reason', value: `> ${ban.reason || 'No reason provided'}`, inline: false },
				{ name: '⏳ Expires', value: `\`${expireDisplay}\``, inline: true },
			])

			if (discordAccount) {
				embed.addFields([{ name: '🔗 Discord', value: `${discordAccount}`, inline: true }])
			}

			interaction.reply({ embeds: [embed] })
		} else {
			let embed = new EmbedBuilder()
				.setColor(0x95A5A6)
				.setTitle('❌ Ban Not Found')
				.setDescription(`No ban was found with ID **#${banId}**.\nDouble-check the ID and try again.`)
				.setTimestamp()
				.setFooter({ text: 'EasyAdmin Ban System' })

			interaction.reply({ embeds: [embed] })
		}
	},
}
