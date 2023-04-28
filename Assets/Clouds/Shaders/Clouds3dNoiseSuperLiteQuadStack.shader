// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "EdShaders/Clouds3dNoiseSuperLiteQuadStack"
{
	Properties
	{
		_Cutoff( "Mask Clip Value", Float ) = 0.5
		_NoiseSize("Noise Size", Float) = 1
		_CloudSpeed("Cloud Speed", Float) = 0
		_CloudCutoff("Cloud Cutoff", Range( 0 , 1)) = 0.2
		_CloudStrength("Cloud Strength", Float) = 1
		_CloudFluctuations("Cloud Fluctuations", Float) = 0
		_SSSPower("SSS Power", Range( 1 , 10)) = 0
		_TaperPower("Taper Power", Float) = 2
		_CloudSoftness("Cloud Softness", Float) = 1
		_SSSStrength("SSS Strength", Float) = 1
		_BottomLightingMultiplier("Bottom Lighting Multiplier", Float) = 1
		_TopLightingMultiplier("Top Lighting Multiplier", Float) = 1
		_FadeOutMask("Fade Out Mask", 2D) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Custom"  "Queue" = "Overlay+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		Blend SrcAlpha OneMinusSrcAlpha
		BlendOp Add
		CGPROGRAM
		#include "UnityPBSLighting.cginc"
		#include "UnityCG.cginc"
		#include "UnityShaderVariables.cginc"
		#pragma target 3.0
		#pragma surface surf StandardCustomLighting keepalpha noshadow 
		struct Input
		{
			float3 worldPos;
			float4 vertexColor : COLOR;
			float2 uv_texcoord;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		uniform float _SSSStrength;
		uniform float _SSSPower;
		uniform float _BottomLightingMultiplier;
		uniform float _TopLightingMultiplier;
		uniform float _CloudSpeed;
		uniform float _CloudFluctuations;
		uniform float _NoiseSize;
		uniform float _TaperPower;
		uniform float _CloudStrength;
		uniform sampler2D _FadeOutMask;
		uniform float4 _FadeOutMask_ST;
		uniform float _CloudCutoff;
		uniform float _CloudSoftness;
		uniform float _Cutoff = 0.5;


		float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }

		float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }

		float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }

		float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }

		float snoise( float3 v )
		{
			const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
			float3 i = floor( v + dot( v, C.yyy ) );
			float3 x0 = v - i + dot( i, C.xxx );
			float3 g = step( x0.yzx, x0.xyz );
			float3 l = 1.0 - g;
			float3 i1 = min( g.xyz, l.zxy );
			float3 i2 = max( g.xyz, l.zxy );
			float3 x1 = x0 - i1 + C.xxx;
			float3 x2 = x0 - i2 + C.yyy;
			float3 x3 = x0 - 0.5;
			i = mod3D289( i);
			float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
			float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
			float4 x_ = floor( j / 7.0 );
			float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
			float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
			float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
			float4 h = 1.0 - abs( x ) - abs( y );
			float4 b0 = float4( x.xy, y.xy );
			float4 b1 = float4( x.zw, y.zw );
			float4 s0 = floor( b0 ) * 2.0 + 1.0;
			float4 s1 = floor( b1 ) * 2.0 + 1.0;
			float4 sh = -step( h, 0.0 );
			float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
			float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
			float3 g0 = float3( a0.xy, h.x );
			float3 g1 = float3( a0.zw, h.y );
			float3 g2 = float3( a1.xy, h.z );
			float3 g3 = float3( a1.zw, h.w );
			float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
			g0 *= norm.x;
			g1 *= norm.y;
			g2 *= norm.z;
			g3 *= norm.w;
			float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
			m = m* m;
			m = m* m;
			float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
			return 42.0 * dot( m, px);
		}


		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			float3 ase_worldPos = i.worldPos;
			float2 appendResult31 = (float2(ase_worldPos.x , ase_worldPos.z));
			float2 break310 = ( appendResult31 + ( _Time.y * _CloudSpeed ) );
			float3 appendResult35 = (float3(break310.x , ( ase_worldPos.y + ( _Time.y * _CloudFluctuations ) ) , break310.y));
			float simplePerlin3D2 = snoise( ( appendResult35 * ( _NoiseSize * 0.1 ) ) );
			float VerticalStep345 = -(-1.0 + (i.vertexColor.a - 0.0) * (1.0 - -1.0) / (1.0 - 0.0));
			float temp_output_346_0 = abs( VerticalStep345 );
			float VerticalFalloff354 = ( ( 1.0 - pow( temp_output_346_0 , _TaperPower ) ) * _CloudStrength );
			float2 uv_FadeOutMask = i.uv_texcoord * _FadeOutMask_ST.xy + _FadeOutMask_ST.zw;
			float temp_output_356_0 = (0.0 + (( simplePerlin3D2 * VerticalFalloff354 * tex2D( _FadeOutMask, uv_FadeOutMask ).r ) - _CloudCutoff) * (1.0 - 0.0) / (1.0 - _CloudCutoff));
			c.rgb = 0;
			c.a = saturate( pow( saturate( temp_output_356_0 ) , _CloudSoftness ) );
			clip( temp_output_356_0 - _Cutoff );
			return c;
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldViewDir = Unity_SafeNormalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float dotResult239 = dot( ase_worldViewDir , -ase_worldlightDir );
			float temp_output_247_0 = pow( saturate( dotResult239 ) , _SSSPower );
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aselc
			float4 ase_lightColor = 0;
			#else //aselc
			float4 ase_lightColor = _LightColor0;
			#endif //aselc
			float4 temp_output_249_0 = ( _SSSStrength * temp_output_247_0 * unity_AmbientSky * ase_lightColor );
			float4 SubsurfaceScattering155 = temp_output_249_0;
			float VerticalStep345 = -(-1.0 + (i.vertexColor.a - 0.0) * (1.0 - -1.0) / (1.0 - 0.0));
			float temp_output_401_0 = (0.0 + (VerticalStep345 - -1.0) * (1.0 - 0.0) / (1.0 - -1.0));
			float4 AmbientLight340 = ( ( unity_AmbientGround * temp_output_401_0 * _BottomLightingMultiplier ) + ( unity_AmbientSky * ( 1.0 - temp_output_401_0 ) * _TopLightingMultiplier ) );
			o.Emission = ( SubsurfaceScattering155 + AmbientLight340 ).rgb;
		}

		ENDCG
	}
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=15600
2685;131;1906;811;3455.642;18.06552;3.414859;True;False
Node;AmplifyShaderEditor.CommentaryNode;366;-4089.429,1383.905;Float;False;600.8883;535.5687;;2;368;367;Quad Stack tapering;1,1,1,1;0;0
Node;AmplifyShaderEditor.VertexColorNode;367;-4013.656,1532.438;Float;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;157;-3034.462,114.2664;Float;False;2103.639;596.2936;;18;31;33;313;41;309;312;2;6;115;114;7;35;308;310;30;4;316;12;3d Noise Generator;1,1,1,1;0;0
Node;AmplifyShaderEditor.TFHCRemapNode;368;-3708.961,1622.453;Float;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;-1;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;323;-3365.5,1587.837;Float;False;1833.463;370.7622;;12;354;353;351;352;350;349;348;346;347;345;344;387;Vertical Falloff and taper;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldPosInputsNode;4;-2943.463,293.0162;Float;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleTimeNode;33;-3001.392,467.635;Float;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;41;-3008.962,560.4485;Float;False;Property;_CloudSpeed;Cloud Speed;2;0;Create;True;0;0;False;0;0;-0.55;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;387;-3218.124,1784.84;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;313;-3008.659,634.0822;Float;False;Property;_CloudFluctuations;Cloud Fluctuations;5;0;Create;True;0;0;False;0;0;0.3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;31;-2692.705,296.6953;Float;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;309;-2776.273,446.0451;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;345;-3017.042,1652.137;Float;False;VerticalStep;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;312;-2620.645,602.9984;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;349;-2403.735,1804.396;Float;False;Property;_TaperPower;Taper Power;7;0;Create;True;0;0;False;0;2;1.62;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;346;-2643.861,1677.961;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;30;-2516.935,319.7587;Float;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;231;-3409.145,789.6068;Float;False;2498.291;607.5538;;14;256;249;248;247;245;244;239;236;235;233;265;303;155;241;SubSurface Scattering;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;7;-2414.765,502.6044;Float;False;Property;_NoiseSize;Noise Size;1;0;Create;True;0;0;False;0;1;1.37;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;310;-2369.67,330.8145;Float;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.PowerNode;350;-2276.667,1682.442;Float;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;114;-2406.783,595.5596;Float;False;Constant;_Float1;Float 1;15;0;Create;True;0;0;False;0;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;308;-2594.032,496.3511;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;352;-2062.718,1660.023;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;115;-2142.393,522.6367;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;351;-2129.893,1799.439;Float;False;Property;_CloudStrength;Cloud Strength;4;0;Create;True;0;0;False;0;1;9.15;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;35;-2117.643,367.3379;Float;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;324;-3348.44,2094.872;Float;False;2313.873;774.9438;;11;340;339;338;337;336;335;334;325;364;365;401;Ambient Light;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;233;-3249.058,1212.297;Float;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;235;-3239.376,1059.539;Float;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;353;-1852.879,1654.394;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;6;-1871.286,471.0083;Float;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NegateNode;236;-3007.598,1192.349;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;325;-3137.025,2608.376;Float;False;345;VerticalStep;0;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;2;-1601.222,442.3647;Float;False;Simplex3D;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;316;-1343.675,310.9198;Float;False;354;VerticalFalloff;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;401;-2914.459,2372.181;Float;False;5;0;FLOAT;0;False;1;FLOAT;-1;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;239;-2933.134,1019.167;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;354;-1740.888,1795.69;Float;False;VerticalFalloff;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;363;-622.3707,643.7963;Float;False;1341.804;383.2949;;6;356;357;359;360;358;355;Opacity;1,1,1,1;0;0
Node;AmplifyShaderEditor.SamplerNode;402;-1547.158,563.5553;Float;True;Property;_FadeOutMask;Fade Out Mask;13;0;Create;True;0;0;False;0;None;3f3c3d4ef4cbb534d9a5bf3f5fe7cea4;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;241;-2812.485,854.1733;Float;False;Property;_SSSPower;SSS Power;6;0;Create;True;0;0;False;0;0;8.55;1;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;244;-2801.979,1020.182;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;364;-2008.42,2403.63;Float;False;Property;_BottomLightingMultiplier;Bottom Lighting Multiplier;11;0;Create;True;0;0;False;0;1;0.3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FogAndAmbientColorsNode;336;-2040.014,2257.775;Float;False;unity_AmbientGround;0;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;355;-572.3707,846.7345;Float;False;Property;_CloudCutoff;Cloud Cutoff;3;0;Create;True;0;0;False;0;0.2;0.089;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;365;-1953.42,2782.63;Float;False;Property;_TopLightingMultiplier;Top Lighting Multiplier;12;0;Create;True;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;334;-1971.625,2584.12;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FogAndAmbientColorsNode;335;-2010.708,2699.098;Float;False;unity_AmbientSky;0;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;12;-1144.256,491.7332;Float;False;3;3;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LightColorNode;248;-2528.9,1240.009;Float;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;337;-1668.349,2488.429;Float;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.FogAndAmbientColorsNode;303;-2316.827,1311.517;Float;False;unity_AmbientSky;0;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;338;-1700.349,2358.429;Float;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.PowerNode;247;-2558.469,1045.195;Float;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;356;-251.7458,825.0912;Float;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;245;-2659.676,1163.615;Float;False;Property;_SSSStrength;SSS Strength;10;0;Create;True;0;0;False;0;1;0.7;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;357;-39.06181,798.8553;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;358;-108.6052,693.7963;Float;False;Property;_CloudSoftness;Cloud Softness;8;0;Create;True;0;0;False;0;1;6.15;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;249;-1845.888,1143.705;Float;False;4;4;0;FLOAT;1;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;339;-1476.26,2416.008;Float;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;156;442.2256,402.2487;Float;False;155;SubsurfaceScattering;0;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;155;-1239.822,1118.755;Float;False;SubsurfaceScattering;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.PowerNode;359;196.4623,713.9383;Float;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;361;464.4766,532.6077;Float;False;340;AmbientLight;0;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;340;-1264.221,2410.771;Float;False;AmbientLight;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;360;544.4332,735.288;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;265;-2107.489,1040.786;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;348;-2501.853,1697.904;Float;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;256;-1559.115,1111.421;Float;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;344;-2930.97,1843.894;Float;False;Property;_cloudHeight;cloudHeight;9;1;[HideInInspector];Create;True;0;0;False;0;0;1.43;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;347;-2700.141,1836.445;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;362;839.492,497.4638;Float;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1105.092,511.4124;Float;False;True;2;Float;ASEMaterialInspector;0;0;CustomLighting;EdShaders/Clouds3dNoiseSuperLiteQuadStack;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;False;0;True;Custom;;Overlay;All;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;2;5;False;-1;10;False;-1;0;5;False;-1;10;False;-1;1;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Spherical;True;Relative;0;;0;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;368;0;367;4
WireConnection;387;0;368;0
WireConnection;31;0;4;1
WireConnection;31;1;4;3
WireConnection;309;0;33;0
WireConnection;309;1;41;0
WireConnection;345;0;387;0
WireConnection;312;0;33;0
WireConnection;312;1;313;0
WireConnection;346;0;345;0
WireConnection;30;0;31;0
WireConnection;30;1;309;0
WireConnection;310;0;30;0
WireConnection;350;0;346;0
WireConnection;350;1;349;0
WireConnection;308;0;4;2
WireConnection;308;1;312;0
WireConnection;352;0;350;0
WireConnection;115;0;7;0
WireConnection;115;1;114;0
WireConnection;35;0;310;0
WireConnection;35;1;308;0
WireConnection;35;2;310;1
WireConnection;353;0;352;0
WireConnection;353;1;351;0
WireConnection;6;0;35;0
WireConnection;6;1;115;0
WireConnection;236;0;233;0
WireConnection;2;0;6;0
WireConnection;401;0;325;0
WireConnection;239;0;235;0
WireConnection;239;1;236;0
WireConnection;354;0;353;0
WireConnection;244;0;239;0
WireConnection;334;0;401;0
WireConnection;12;0;2;0
WireConnection;12;1;316;0
WireConnection;12;2;402;1
WireConnection;337;0;335;0
WireConnection;337;1;334;0
WireConnection;337;2;365;0
WireConnection;338;0;336;0
WireConnection;338;1;401;0
WireConnection;338;2;364;0
WireConnection;247;0;244;0
WireConnection;247;1;241;0
WireConnection;356;0;12;0
WireConnection;356;1;355;0
WireConnection;357;0;356;0
WireConnection;249;0;245;0
WireConnection;249;1;247;0
WireConnection;249;2;303;0
WireConnection;249;3;248;0
WireConnection;339;0;338;0
WireConnection;339;1;337;0
WireConnection;155;0;249;0
WireConnection;359;0;357;0
WireConnection;359;1;358;0
WireConnection;340;0;339;0
WireConnection;360;0;359;0
WireConnection;265;0;248;0
WireConnection;265;1;247;0
WireConnection;348;0;346;0
WireConnection;348;1;347;0
WireConnection;256;0;265;0
WireConnection;256;1;249;0
WireConnection;347;0;344;0
WireConnection;362;0;156;0
WireConnection;362;1;361;0
WireConnection;0;2;362;0
WireConnection;0;9;360;0
WireConnection;0;10;356;0
ASEEND*/
//CHKSM=804EBA80AEBA90E273048AA2D5E265D458D3545C