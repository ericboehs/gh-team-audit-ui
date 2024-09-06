# frozen_string_literal: true

require 'bundler/setup'
Bundler.require 'default', 'development'

require 'dotenv'
Dotenv.load '.env.local', '.env'

require 'csv'
require 'date'
require 'json'
require 'fileutils'
require 'pry'
