

module.exports = {
	data: new SlashCommandBuilder()
		.setName('warn')
		.setDescription('Warns a player')
		.addStringOption(option =>
			option.setName('user')
				.setDescription('Username or Server ID')
				.setRequired(true))
		.addStringOption(option =>
			option.setName('reason')
				.setDescription('Reason for the warning')
				.setRequired(true)),
	async execute(interaction, exports) {
		if (!await DoesGuildMemberHavePermission(interaction.member, 'player.warn')) {
			return interaction.reply({ content: 'Insufficient permissions: `easyadmin.player.warn`', ephemeral: true })
		}

		const userOrId = interaction.options.getString('user')
		const reason = exports[EasyAdmin].formatShortcuts(interaction.options.getString('reason'))

		const user = await findPlayerFromUserInput(userOrId)

		if (!user || user.dropped) {
			let embed = new EmbedBuilder()
				.setColor(0xE74C3C)
				.setTitle('❌ Player Not Found')
				.setDescription(`No online player found matching \`${userOrId}\`.`)
				.setTimestamp()
			return interaction.reply({ embeds: [embed], ephemeral: true })
		}

		var src = interaction.user.tag
		var ret = await exports[EasyAdmin].warnPlayer(src, user.id, reason)

		let embed
		if (ret) {
			embed = new EmbedBuilder()
				.setColor(0xF1C40F)
				.setTitle('⚠️ Player Warned')
				.addFields([
					{ name: '👤 Player', value: `\`${user.name}\` (ID: ${user.id})`, inline: true },
					{ name: '🛡️ Warned By', value: `${interaction.user}`, inline: true },
					{ name: '📋 Reason', value: `> ${reason}`, inline: false },
				])
				.setTimestamp()
				.setFooter({ text: `Issued via Discord • ${interaction.user.tag}` })
		} else {
			embed = new EmbedBuilder()
				.setColor(0xE74C3C)
				.setTitle('❌ Warning Failed')
				.setDescription(`Could not warn **${user.name}** — they may be immune.`)
				.setTimestamp()
		}
		await interaction.reply({ embeds: [embed] })
	},
}
