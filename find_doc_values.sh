#!/bin/bash
#
# Look inside Elasticsearch indexes which fields are stored on disk (doc_values)
# Copyright (C) 2016 Julien Pivotto <roidelapluie@inuits.eu>
#
# Usage: ./find_doc_values.sh http://elastic:9200
# Requires JQ https://stedolan.github.io/jq
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

ELASTICSEARCH_URL=${1:?Please pass the Elastic URL as parameter}
curl -s "${ELASTICSEARCH_URL}/_all/_mapping" > _mapping

select index in $(cat _mapping|jq -r '.|keys|.[]')
do
    cat _mapping | jq -r ".[\"$index\"].mappings[].properties|keys|.[]"|
    while read y
    do
        url="${ELASTICSEARCH_URL}/$index/_mapping/field/${y}?include_defaults=true&pretty"
        curl "$url" -s > _field

        echo -en "$index>$y: "
        if grep  doc_value < _field|grep -q false
        then
            echo -en "\e[1;31min-memory\e[0m"
        elif  grep doc_value < _field|grep -q true
        then
            echo -en "\e[1;32mdoc_value\e[0m"
        fi
        rm _field
        echo
    done
done
rm _mapping
