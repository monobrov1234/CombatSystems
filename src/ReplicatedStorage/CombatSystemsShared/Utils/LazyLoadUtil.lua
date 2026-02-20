local module = {}

function module.objectSupplier<T>(objectInit: () -> T): () -> T
	local cached
	return function()
		if not cached then cached = objectInit() end
		return cached
	end
end

return module
