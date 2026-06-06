

module.exports = {
	data: new SlashCommandBuilder()
		.setName('baninfo')
		.setDescription('Shows details of a ban')
		.addStringOption(option =>
			option.setName('banid')
				.setDescription('Ban ID')
				.setRequired(true)),
	async execute(interaction, exports) {
		const banIdRaw = interaction.options.getString('banid').trim()
		// Support both numeric and alphanumeric ban IDs
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

			const expireDisplay = ban.expireString || 'Permanent'
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
