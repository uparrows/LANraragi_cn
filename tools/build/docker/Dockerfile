# DOCKER-VERSION 0.3.4
FROM        alpine:3.12
LABEL       git="https://github.com/uparrows/LANraragi_cn"

ENV S6_OVERLAY_RELEASE v2.0.0.1
ENV S6_KEEP_ENV 1

# warn if we can't run stage2 (fix-attrs/cont-init)
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS 1

# wait 10s before KILLing
ENV S6_KILL_GRACETIME 10000

# s6
ENTRYPOINT ["/init"] 

# Check application health
HEALTHCHECK --interval=1m --timeout=10s --retries=3 \
  CMD wget --quiet --tries=1 --no-check-certificate --spider \
  http://localhost:3000 || exit 1

#Default mojo server port
EXPOSE 3000

#Enable UTF-8 (might not do anything extra on alpine tho)
ENV LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 \
    #rootless user id
    LRR_UID=0 LRR_GID=0 \
    #Environment variables overridable by the user on container deployment
    LRR_NETWORK=http://*:3000 \
    # extra variables
    EV_EXTRA_DEFS=-DEV_NO_ATFORK



# we use s6-overlay-nobin to just pull in the s6-overlay arch agnostic (shell)
# components, since we apk install the binaries of s6 later which are arch specific
# /!\ While the s6 version here is fixed by an envvar, the apk install is not pinned and takes whatever's in alpine:latest! This certainly needs a fix.
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_RELEASE}/s6-overlay-nobin.tar.gz /tmp/s6-overlay-nobin.tar.gz
RUN tar -C / -xzf /tmp/s6-overlay-nobin.tar.gz && rm -f /tmp/s6-overlay-nobin.tar.gz


WORKDIR /home/dezhao/lanraragi

#Copy cpanfile and install script before copying the entire context
#This allows for Docker cache to preserve cpan dependencies
COPY --chown=root:root /tools/cpanfile /tools/install.pl /tools/build/docker/install-everything.sh tools/
COPY --chown=root:root /package.json package.json

# Run the install script as root
RUN sh ./tools/install-everything.sh
RUN rm -f /home/dezhao/lanraragi/public/js/vendor/jquery.dataTables.min.js
#Copy remaining LRR files from context
# consider chowning in s6 setup scripts instead
COPY --chown=root:root /lib lib
COPY --chown=root:root /public public
COPY --chown=root:root /script script
COPY --chown=root:root /templates templates
COPY --chown=root:root /tests tests
COPY --chown=root:root /lrr.conf lrr.conf
COPY --chown=root:root /tools/build/docker/redis.conf tools/build/docker/
COPY /tools/build/docker/wsl.conf /etc/wsl.conf
COPY /tools/build/docker/s6/cont-init.d/ /etc/cont-init.d/
COPY /tools/build/docker/s6/services.d/ /etc/services.d/
COPY --chown=root:root /jquery.dataTables.min.js /home/dezhao/lanraragi/public/js/vendor/jquery.dataTables.min.js
#COPY /tools/build/docker/s6/fix-attrs.d/ /etc/fix-attrs.d/

# Persistent volumes
VOLUME [ "/home/dezhao/lanraragi/content" ]
VOLUME [ "/home/dezhao/lanraragi/database"]
