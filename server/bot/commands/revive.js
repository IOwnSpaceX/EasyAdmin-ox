

module.exports = {
	data: new SlashCommandBuilder()
		.setName('revive')
		.setDescription('Revives a downed/dead player')
		.addStringOption(option =>
			option.setName('user')
				.setDescription('Username or Server ID')
				.setRequired(true)),
	async execute(interaction, exports) {
		if (!await DoesGuildMemberHavePermission(interaction.member, 'player.adrev')) {
			return interaction.reply({ content: 'Insufficient permissions: `easyadmin.player.adrev`', ephemeral: true })
		}

		const userOrId = interaction.options.getString('user')
		const user = await findPlayerFromUserInput(userOrId)

		if (!user || user.dropped) {
			let embed = new EmbedBuilder()
				.setColor(0xE74C3C)
				.setTitle('❌ Player Not Found')
				.setDescription(`No online player found matching \`${userOrId}\`.`)
				.setTimestamp()
			return interaction.reply({ embeds: [embed], ephemeral: true })
		}

		TriggerClientEvent('DeathScript:Admin:Revive', user.id, 0, false)

		LogDiscordMessage(
			`💊 **${interaction.user.tag}** revived **${user.name}** (ID: ${user.id})`,
			'revive',
			0x2ECC71
		)

		let embed = new EmbedBuilder()
			.setColor(0x2ECC71)
			.setTitle('💊 Player Revived')
			.addFields([
				{ name: '👤 Player', value: `\`${user.name}\` (ID: ${user.id})`, inline: true },
				{ name: '🛡️ Revived By', value: `${interaction.user}`, inline: true },
			])
			.setTimestamp()
			.setFooter({ text: `Issued via Discord • ${interaction.user.tag}` })

		await interaction.reply({ embeds: [embed] })
	},
}
