return {
  description = "SQL",
  filetypes = { "sql", "mysql" },
  parsers = { "sql" },
  servers = {
    sqls = { cmd = "sqls", mason = "sqls", install = "go install github.com/sqls-server/sqls@latest" },
  },
  formatters = {
    sql_formatter = {
      cmd = "sql-formatter",
      mason = "sql-formatter",
      filetypes = { "sql", "mysql" },
      install = "npm install -g sql-formatter",
    },
  },
}
