Shader "Ethan/EngineRim"
{
    Properties
    {
        // Metal (Lambert) Properties
        _BaseColor ("Base Color", Color) = (.25, .25, .25, 1) // Metal Colour
        _SpecularColor("Specular Color", Color) = (1,1,1,1)
        _Shininess("Shininess", Range(1, 100)) = 30

        // Rim Properties
        _RimColor ("Rim Color", Color) = (1, 0.5, 0, 1) // Heat colour
        _RimPower ("Rim Power", Range(0.5, 8.0)) = 3.0 // Sharpness of heat rim lighting
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "RenderType" = "Opaque" }
        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;

                float4 tangentOS : TANGENT; // Tangent for rim light
            };
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 viewDirWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)

                // Lambert properties
                float4 _BaseColor; 
                float4 _SpecularColor;
                float _Shininess;

                // Rim properties
                float4 _RimColor;
                float _RimPower;

            CBUFFER_END

            // Vertex Shader
            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                // Transform object space position to homogeneous clip-space position
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);

                // Transform object space normal to world space
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));

                // Calculate the view direction in world space (from the camera to the surface)
                float3 worldPosWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.viewDirWS = normalize(GetCameraPositionWS() - worldPosWS);

                return OUT;
            }

            // Fragment Shader
            half4 frag(Varyings IN) : SV_Target
            {
                
                // Cache main light, normalDir, and viewDIr
                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);
                half3 normalWS = normalize(IN.normalWS);
                half3 viewDirWS = normalize(IN.viewDirWS);

                // Lambertian diffuse lighting
                half NdotL = saturate(dot(normalWS, lightDir));
                half3 diffuse = _BaseColor.rgb * NdotL * mainLight.color;

                // Calculate specular highlights
                half3 viewDir = normalize(IN.viewDirWS);
                half3 halfDir = normalize(lightDir + viewDir);
                half specFactor = pow(saturate(dot(normalWS, halfDir)), _Shininess);
                half3 specular = _SpecularColor.rgb * specFactor * mainLight.color;

                // Get ambient light
                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                // Calculate rim lighting
                half rimFactor = 1.0 - saturate(dot(viewDirWS, normalWS));
                half rimLighting = pow(rimFactor, _RimPower);

                // Combine lambert shading with rim lighting for a heated metal effect
                half3 finalColor = ambient + diffuse + specular + _RimColor.rgb * rimLighting;
                return half4(finalColor, _BaseColor.a);
            }
            ENDHLSL
        }
    }
}