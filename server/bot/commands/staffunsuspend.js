

module.exports = {
	data: new SlashCommandBuilder()
		.setName('staffunsuspend')
		.setDescription('Remove a duty suspension from a staff member')
		.addStringOption(option =>
			option.setName('discord')
				.setDescription('Discord ID or @mention of the staff member')
				.setRequired(true)),
	async execute(interaction, exports) {
		if (!await DoesGuildMemberHavePermission(interaction.member, 'clockin.suspend')) {
			return interaction.reply({ content: 'Insufficient permissions: `clockin.suspend`', ephemeral: true })
		}

		const discordInput = interaction.options.getString('discord')
		const discordId    = discordInput.replace(/[<@!>]/g, '')
		const suspensions  = exports[EasyAdmin].getSuspensions()

		if (!suspensions[discordId]) {
			const embed = new EmbedBuilder()
				.setColor(0xE74C3C)
				.setTitle('❌ Not Suspended')
				.setDescription(`<@${discordId}> does not have an active duty suspension.`)
				.setTimestamp()
			return interaction.reply({ embeds: [embed], ephemeral: true })
		}

		exports[EasyAdmin].unsuspendPlayer(discordId)

		const embed = new EmbedBuilder()
			.setColor(0x2ECC71)
			.setTitle('✅ Duty Suspension Lifted')
			.addFields(
				{ name: '🎮 Discord',   value: `<@${discordId}>`,              inline: true },
				{ name: '👮 Lifted By', value: `\`${interaction.user.tag}\``,  inline: true }
			)
			.setFooter({ text: 'EasyAdmin Duty System' })
			.setTimestamp()

		return interaction.reply({ embeds: [embed] })
	}
}
