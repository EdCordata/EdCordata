FROM pandoc/latex

RUN apk add --no-cache font-noto
RUN tlmgr install enumitem

# Copy filters & Styles
COPY ./.docker/md-to-pdf/custom_tags.lua   /custom_tags.lua
COPY ./.docker/md-to-pdf/link_styles.lua   /link_styles.lua
COPY ./.docker/md-to-pdf/header_styles.lua /header_styles.lua

# Set custom entrypoint
COPY ./.docker/md-to-pdf/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
