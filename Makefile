#
# Ogr - The anonymous, static, gradebook generator.
#
# Copyright 2018 Harlan J. Waldrop <harlan@ieee.org>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

DATABASE = gradebook.db
SETTINGS = settings.yml

www/config.php: $(SETTINGS)
	bin/ogr config --from $^ $@

install: $(DATABASE)
	sqlite3 $^ < sql/create.sql
	chmod 0655 $^

.PHONY: install
