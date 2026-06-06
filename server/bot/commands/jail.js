

module.exports = {
	data: new SlashCommandBuilder()
		.setName('jail')
		.setDescription('Jails a player for a set duration')
		.addStringOption(option =>
			option.setName('user')
				.setDescription('Username or Server ID')
				.setRequired(true))
		.addIntegerOption(option =>
			option.setName('duration')
				.setDescription('Jail time in seconds')
				.setRequired(true)
				.setMinValue(1))
		.addStringOption(option =>
			option.setName('reason')
				.setDescription('Reason for jail')
				.setRequired(true)),
	async execute(interaction, exports) {
		const userOrId = interaction.options.getString('user')
		const duration = interaction.options.getInteger('duration')
		const reason = interaction.options.getString('reason')

		const user = await findPlayerFromUserInput(userOrId)

		if (!user || user.dropped) {
			let embed = new EmbedBuilder()
				.setColor(0xE74C3C)
				.setTitle('❌ Player Not Found')
				.setDescription(`No online player found matching \`${userOrId}\`.`)
				.setTimestamp()
			return interaction.reply({ embeds: [embed], ephemeral: true })
		}

		// Trigger the jail event server-side (source = 0 = server console)
		TriggerEvent('Liam:JailPlayerServer', user.id, duration, reason, 0)

		// Log to action history
		const discordId = user.identifiers
			? (user.identifiers.find(i => i.startsWith('discord:')) || '').replace('discord:', '')
			: ''
		if (discordId) {
			exports[EasyAdmin].addActionHistory('~y~JAILED~w~~s~', discordId, `${reason}. Time: ${duration} seconds.`, interaction.user.tag, `discord:${interaction.user.id}`)
		}

		// Log to jail log channel
		LogDiscordMessage(
			`🔒 **${interaction.user.tag}** jailed **${user.name}** (ID: ${user.id}) for **${duration}s** — ${reason}`,
			'jail',
			0xE67E22
		)

		let embed = new EmbedBuilder()
			.setColor(0xE67E22)
			.setTitle('🔒 Player Jailed')
			.addFields([
				{ name: '👤 Player', value: `\`${user.name}\` (ID: ${user.id})`, inline: true },
				{ name: '⏱️ Duration', value: `\`${duration} seconds\``, inline: true },
				{ name: '🛡️ Jailed By', value: `${interaction.user}`, inline: true },
				{ name: '📋 Reason', value: `> ${reason}`, inline: false },
			])
			.setTimestamp()
			.setFooter({ text: `Issued via Discord • ${interaction.user.tag}` })

		await interaction.reply({ embeds: [embed] })
	},
}
