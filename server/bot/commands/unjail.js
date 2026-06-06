

module.exports = {
	data: new SlashCommandBuilder()
		.setName('unjail')
		.setDescription('Releases a player from jail')
		.addStringOption(option =>
			option.setName('user')
				.setDescription('Username or Server ID')
				.setRequired(true)),
	async execute(interaction, exports) {
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

		TriggerEvent('Liam:UnjailPlayerServer', user.id)

		// Log to action history
		const discordId = user.identifiers
			? (user.identifiers.find(i => i.startsWith('discord:')) || '').replace('discord:', '')
			: ''
		if (discordId) {
			exports[EasyAdmin].addActionHistory('~g~UNJAILED~w~~s~', discordId, 'Released from jail via Discord', interaction.user.tag, `discord:${interaction.user.id}`)
		}

		// Log to jail log channel
		LogDiscordMessage(
			`🔓 **${interaction.user.tag}** released **${user.name}** (ID: ${user.id}) from jail`,
			'jail',
			0x2ECC71
		)

		let embed = new EmbedBuilder()
			.setColor(0x2ECC71)
			.setTitle('🔓 Player Released from Jail')
			.addFields([
				{ name: '👤 Player', value: `\`${user.name}\` (ID: ${user.id})`, inline: true },
				{ name: '🛡️ Released By', value: `${interaction.user}`, inline: true },
			])
			.setTimestamp()
			.setFooter({ text: `Issued via Discord • ${interaction.user.tag}` })

		await interaction.reply({ embeds: [embed] })
	},
}
