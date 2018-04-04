macroScript PBR_Creatror
category:"[3DGROUND]"
toolTip:"PBR Creator"
buttontext:"PBR Creator"
(
		
	/*  
	[INFO] 
	NAME = PBR Creator
	VERSION = 1.0.2
	AUTHOR = Vasily Lukyanenko
	DEV = 3DGROUND
	CUSTOMER = Sergey Pak
	SKYPE = ssearsh
	HELP = 
	[1.0.0]
	* First release =
	[1.0.1]
	+ Added: Black color for Self Illumination =
	
	[1.0.2]
	- BugFix: Open rollout exception =
	* Changed: Ior bitmap in to FresnelIor

	[ABOUT]
	Load objects from file in to position.=
	[TEST]
	[SCRIPT]
	*/	


	on execute do (
		try(closeRolloutFloater f_PBR_Create)catch()
		local f_PBR_Create = newRolloutFloater "Create PBR Material" 280 320

		rollout r_PBR_Create "Main" (
			local texturesList = #()
			
			group "Material Name (Optional)"
			(
				edittext edtMatName ""
			)
			
			group "Textures List"
			(
				listbox lbxTexList "" height: 7
				button btnTexLoad "Load Textures"
			)
			
			button btnCreate "Create And Assign" offset: [0, 10] width: 250 height: 35
			
			fn getOpenImage = 
			(
				f = #()
				
				imageDialog = dotNetObject "System.Windows.Forms.OpenFileDialog" 
				imageDialog.title = "Select Preview"
				imageDialog.Multiselect = true
				imageDialog.Filter = "JPG (*.jpg)|*.jpg|PNG (*.png)|*.png|BMP (*.bmp)|*bmp"
				imageDialog.FilterIndex = 1
				
				result = imageDialog.showDialog() 
				result.ToString() 
				result.Equals result.OK 
				result.Equals result.Cancel 
				
				f = imageDialog.fileNames 
				 
				return f
			)
			
			fn isCorona =
			(
				r = renderers.current as string
				if matchpattern r pattern:"*Corona*" do return true		
				return false
			)
			
			fn displayTexList = (
				lbxTexList.items = for t in texturesList collect getFileNameFile t
			)
			
			on btnTexLoad pressed do (
				texturesList = getOpenImage()		
				if(texturesList.count == 0) do return false
				
				displayTexList()
			)
			
			fn getBitmap t = BitmapTex filename: t name: (getFileNameFile t)
			fn getColorCorrection t = (	
				cc = ColorCorrection()
				cc.gammaRGB = 4.4
				cc.lightnessMode = 1
				cc.map = getBitmap t
				
				return cc
			)
			
			fn setNormalBump m n: undefined a: undefined =
			(
				if(m.texmapBump == undefined) do m.texmapBump = CoronaNormal()
				m.texmapBump.addGamma = on
				if(n != undefined) do m.texmapBump.normalMap = getBitmap n
				if(a != undefined) do m.texmapBump.additionalBump = getBitmap a		
			)
			
			fn getName t =
			(
				p = filterString (getFileNameFile t) "_"
				n = "Material "
				if(p.count > 1) do for i in 1 to p.count - 1 do n += p[i] + "_"
				n = trimRight n "_"
				
				return n
			)
			
			on btnCreate pressed do
			(
				if(texturesList.count == 0) do return MessageBox "Please select at least one texture!" title: "Warning!"
				if(selection.count == 0) do return MessageBox "Please select object!" title: "Warning!"
				if(not isCorona()) do return MessageBox "Please assign Corona Renderer!" title: "Warning!"
					
				m = CoronaMtl()

				if(edtMatName.text.count > 0) then (
					m.name = edtMatName.text
				) else (			
					m.name = getName texturesList[1]
				)
				
				-- Default Values
				m.fresnelIor = 1.52
				m.ior = 1.52
				
				
				-- Detect Texture Types
				for t in texturesList do (
					s = filterString (getFileNameFile t) "_"
					n = toLower s[s.count]
					case n of
					(
						"diffuse": (					
							m.texmapDiffuse = getBitmap t
						)
						"emissive": (
							m.levelSelfIllum = 1.0
							m.colorSelfIllum = color 0 0 0
							m.texmapSelfIllum = getBitmap t
						)
						"glossiness": (	
							m.levelReflect = 1.0					
							m.texmapReflectGlossiness = getColorCorrection t
						)				
						"ior": (							
							m.levelReflect = 1.0	
							m.texmapFresnelIor = getColorCorrection t
						)
						"reflection": (							
							m.levelReflect = 1.0	
							m.texmapReflect = getBitmap t
						)
						"normal": (
							setNormalBump m n: t
						)				
						"height": (
							setNormalBump m a: t
						)
						"alpha": (												
							m.texmapOpacity = getBitmap t
						)
										
						default: (
							print ("Unknown type: " + n)
						)
					)
				)
					
				-- Assign Material To Selection
				for o in selection do try(o.material = m) catch()		
				
				return MessageBox ("Material \"" + m.name + "\" created and assigned!") title: "Success!" beep: false
			)
		)

		rollout _rAbout "About" 
		(
			label lblName "" 
			label lblVer "" 
			
			label lblAuthor "" height: 30
			label lblCopy ""  height: 30
			
			local c = color 200 200 200 
			hyperLink href1 "http://3dground.net/" address: "http://3dground.net/" align: #center hoverColor: c visitedColor: c offset: [0, 20]
			
			
			on _rAbout open do
			(					
				lblName.caption = "PBR Creator"
				lblAuthor.caption = "MastaMan"
				lblVer.caption = "1.0.0"
				lblCopy.caption = ""
			)
		)

		addRollout r_PBR_Create f_PBR_Create 
		addRollout _rAbout f_PBR_Create rolledUp:true
	)
)
