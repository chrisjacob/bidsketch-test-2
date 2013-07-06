class ProposalViewerController < ApplicationController

    def show
        template_file = RAILS_ROOT + '/public/proposal-template/index.html'
        result = 'File not found'

        if File.exist?(template_file)
            template_string = File.read(template_file)

            client = Client.find(params[:id])

            proposal = Proposal.find(client)

            proposal_sections = ProposalSection.all(:joins => :proposal, :order => "created_at")

            #
            # Simple token replacement
            #
            # http://stackoverflow.com/questions/8132492/ruby-multiple-string-replacement
            map = {
                # fix relative paths
                'style/style.css' => '/proposal-template/style/style.css',
                'images/logo-footer.png' => '/proposal-template/images/logo-footer.png',
                # replace these placeholders
                '{client_name}' => client.name,
                '{client_company}' => client.company,
                '{client_website}' => client.website,
                '{proposal_name}' => proposal.name,
                '{proposal_send_date}' => proposal.send_date,
                '{proposal_user_name}' => proposal.user_name

            }
            re = Regexp.new(map.keys.map { |x| Regexp.escape(x) }.join('|'))
            result = template_string.gsub(re) { |m| map[m] }

            #
            # Looping token replacement
            #
            token_start = '<!-- Populate and repeat this HTML for each proposal section -->'
            token_end = '<!-- end repeat -->'

            # get template from within the start and end tokens
            split_start = result.split(token_start)
            split_start_head = split_start[0]
            split_start_tail = split_start[1]
            split_end = split_start_tail.split(token_end)
            split_end_head = split_end[0]
            split_end_tail = split_end[1]

            loop_template = split_end_head
            loop_result = ''

            proposal_sections.each do |proposal_section|
                map = {
                    # replace these placeholders
                    '{section_header}' => proposal_section.name,
                    '{section_content}' => proposal_section.description
                }
                re = Regexp.new(map.keys.map { |x| Regexp.escape(x) }.join('|'))
                loop_item = loop_template.gsub(re) { |m| map[m] }

                loop_result += loop_item
            end

            # rebuiled results from split pieces
            result = split_start_head + token_start + loop_result + token_end + split_end_tail
        end

        render :text => result
    end

end
