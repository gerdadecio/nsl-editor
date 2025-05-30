# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#
#   This file is part of the NSL Editor.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
class Search::User::FieldRule
  RULES = {
    "id:" => { where_clause: " id = ? " },
    "user-name:" => { where_clause: " lower(user_name) like ? " },
    "given:" => { where_clause: " lower(given_name) like ? " },
    "family:" => { where_clause: " lower(family_name) like ? " },
    "role:" => { where_clause: " id in (select user_id from user_product_role_v where role like lower(?))" },
    "product:" => { where_clause: " id in (select user_id from user_product_role_v where product like upper(?))" },
    "product-role:" => { where_clause: " id in (select user_id from user_product_role_v where lower(product)||' '||role like lower(?))" },
  }.freeze
end
