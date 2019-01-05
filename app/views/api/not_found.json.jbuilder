if @camelize
  json.key_format! camelize: :lower
end

json.errors do
  json.set!(@item, ['not_found'])
end
