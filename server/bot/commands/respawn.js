

module.exports = {
	data: new SlashCommandBuilder()
		.setName('respawn')
		.setDescription('Respawns a player at their last checkpoint')
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

		TriggerClientEvent('DeathScript:Admin:Respawn', user.id, 0, false)

		// Log to action history
		const discordId = user.identifiers
			? (user.identifiers.find(i => i.startsWith('discord:')) || '').replace('discord:', '')
			: ''
		if (discordId) {
			exports[EasyAdmin].addActionHistory('~b~RESPAWNED~w~~s~', discordId, 'Respawned via Discord', interaction.user.tag, `discord:${interaction.user.id}`)
		}

		LogDiscordMessage(
			`🔄 **${interaction.user.tag}** respawned **${user.name}** (ID: ${user.id})`,
			'respawn',
			0x3498DB
		)

		let embed = new EmbedBuilder()
			.setColor(0x3498DB)
			.setTitle('🔄 Player Respawned')
			.addFields([
				{ name: '👤 Player', value: `\`${user.name}\` (ID: ${user.id})`, inline: true },
				{ name: '🛡️ Respawned By', value: `${interaction.user}`, inline: true },
			])
			.setTimestamp()
			.setFooter({ text: `Issued via Discord • ${interaction.user.tag}` })

		await interaction.reply({ embeds: [embed] })
	},
}
