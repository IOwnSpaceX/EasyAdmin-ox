

module.exports = {
	data: new SlashCommandBuilder()
		.setName('kick')
		.setDescription('Kicks a player from the server')
		.addStringOption(option =>
			option.setName('user')
				.setDescription('Username or Server ID')
				.setRequired(true))
		.addStringOption(option =>
			option.setName('reason')
				.setDescription('Reason for kick')
				.setRequired(true)),
	async execute(interaction, exports) {
		if (!await DoesGuildMemberHavePermission(interaction.member, 'player.kick')) {
			return interaction.reply({ content: 'Insufficient permissions: `easyadmin.player.kick`', ephemeral: true })
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

		DropPlayer(user.id, exports[EasyAdmin].GetLocalisedText('kicked').replace('%s', interaction.user.tag).replace('%s', reason))

		let embed = new EmbedBuilder()
			.setColor(0xF39C12)
			.setTitle('👢 Player Kicked')
			.addFields([
				{ name: '👤 Player', value: `\`${user.name}\` (ID: ${user.id})`, inline: true },
				{ name: '🛡️ Kicked By', value: `${interaction.user}`, inline: true },
				{ name: '📋 Reason', value: `> ${reason}`, inline: false },
			])
			.setTimestamp()
			.setFooter({ text: `Issued via Discord • ${interaction.user.tag}` })

		await interaction.reply({ embeds: [embed] })
	},
}
