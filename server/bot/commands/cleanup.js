

module.exports = {
	data: new SlashCommandBuilder()
		.setName('cleanup')
		.setDescription('Cleans up area of type')
		.addStringOption(option =>
			option.setName('type')
				.setDescription('Type of Entity to clean up.')
				.setRequired(true)
				.addChoices(
					{name:'Vehicles', value:'cars'},
					{name:'Peds', value:'peds'},
					{name:'Props', value:'props'})),
		
	async execute(interaction, exports) {
		if (!await DoesGuildMemberHavePermission(interaction.member, 'server.cleanup')) {
			return interaction.reply({ content: 'Insufficient permissions: `easyadmin.server.cleanup`', ephemeral: true })
		}

		const type = interaction.options.getString('type')
		var ret = exports[EasyAdmin].cleanupArea(type)

		if (ret) {
			let embed = await prepareGenericEmbed(`Cleaned up **${type}**.`)
			await interaction.reply({ embeds: [embed]})
		} else {
			let embed = await prepareGenericEmbed(`Could not cleanup **${type}**.`)
			await interaction.reply({ embeds: [embed]})
		}
	},
}
