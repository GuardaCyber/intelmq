# -*- coding: utf-8 -*-
"""
TODO: IPv6
"""
from __future__ import unicode_literals
import sys

import dns
from dns import resolver, reversename

from intelmq.lib.bot import Bot
from intelmq.lib.cache import Cache
from intelmq.lib.harmonization import IPAddress

MINIMUM_BGP_PREFIX_IPV4 = 24
MINIMUM_BGP_PREFIX_IPV6 = 128  # FIXME


class ReverseDnsExpertBot(Bot):

    def init(self):
        self.cache = Cache(self.parameters.redis_cache_host,
                           self.parameters.redis_cache_port,
                           self.parameters.redis_cache_db,
                           self.parameters.redis_cache_ttl,
                           )

    def process(self):
        event = self.receive_message()

        if event is None:
            self.acknowledge_message()
            return

        keys = ["source.%s", "destination.%s"]

        for key in keys:
            ip_key = key % "ip"

            if not event.contains(ip_key):
                continue

            ip = event.value(ip_key)
            ip_version = IPAddress.version(ip)
            ip_integer = IPAddress.to_int(ip)

            if ip_version == 4:
                minimum = MINIMUM_BGP_PREFIX_IPV4

            elif ip_version == 6:
                minimum = MINIMUM_BGP_PREFIX_IPV6

            else:
                self.logger.error("Invalid IP version {!r}".format(ip_version))
                self.send_message(event)
                self.acknowledge_message()

            cache_key = bin(ip_integer)[2: minimum + 2]
            cachevalue = self.cache.get(cache_key)

            result = None
            if cachevalue:
                result = cachevalue
            else:
                rev_name = reversename.from_address(ip)
                try:
                    result = str(resolver.query(rev_name, "PTR")[0])
                except dns.exception.DNSException as e:
                    if isinstance(e, dns.resolver.NXDOMAIN):
                        continue
                else:
                    self.cache.set(cache_key, result)

            if result is not None:
                event.add(key % 'reverse_dns',
                          result, sanitize=True, force=True)

        self.send_message(event)
        self.acknowledge_message()


if __name__ == "__main__":
    bot = ReverseDnsExpertBot(sys.argv[1])
    bot.start()