

module.exports = {
	data: new SlashCommandBuilder()
		.setName('unban')
		.setDescription('Unbans a player by ban ID')
		.addStringOption(option =>
			option.setName('banid')
				.setDescription('Ban ID')
				.setRequired(true)),
	async execute(interaction, exports) {
		const banIdRaw = interaction.options.getString('banid').trim()
		const banId = isNaN(banIdRaw) ? banIdRaw : parseInt(banIdRaw)

		var ret = await exports[EasyAdmin].unbanPlayer(banId)

		if (ret == true) {
			let embed = new EmbedBuilder()
				.setColor(0x2ECC71)
				.setTitle('✅ Ban Removed')
				.setDescription(`Ban **#${banId}** has been successfully lifted.`)
				.setTimestamp()
				.setFooter({ text: `Unbanned by ${interaction.user.tag}` })

			await interaction.reply({ embeds: [embed] })
		} else {
			let embed = new EmbedBuilder()
				.setColor(0xE74C3C)
				.setTitle('❌ Unban Failed')
				.setDescription(`Could not remove ban **#${banId}**.\nMake sure the ID is valid and the ban exists.`)
				.setTimestamp()
				.setFooter({ text: 'EasyAdmin Ban System' })

			await interaction.reply({ embeds: [embed] })
		}
	},
}
