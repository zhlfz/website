<div class="container footer">
	<div class="span24">
		[@ad_position id = 2 /]
	</div>
	<div class="span24">
		<ul class="bottomNav">
			[@navigation_list position = "bottom"]
				[#list navigations as navigation]
					<li>
						<a href="${navigation.url}"[#if navigation.isBlankTarget] target="_blank"[/#if]>${navigation.name}</a>
						[#if navigation_has_next]|[/#if]
					</li>
				[/#list]
			[/@navigation_list]
		</ul>
	</div>
	<div class="span24">
		<div class="copyright">${message("shop.footer.copyright", setting.siteName)}</div>
	</div>
	[#include "/shop/include/statistics.ftl" /]
</div>